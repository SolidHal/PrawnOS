
Now that we can boot into a rootfs, there are many things to do:

### Build system support
- tooling to create server oriented rootfs: DONE
- tooling to create images bootable from sdcard : DONE
- tooling to build uboot upstream
  - build u-boot upstream
  - bring in rk/firefly patches / config
  - investigate the rk bootloader
     - !!! how does the stock system write a new uboot image?
       - look at the partition layout of the mmc
     - can we have A/B uboot images?
- create & bring in patches from the kernel tree : https://github.com/SolidHal/rk3588-kernel-libre
  - right now we are just cloning the patched kernel git repo in kernel/makefile

### Scripting/system support
- Scripting to install to emmc
- network/ssh login
  - configure server: let user specify root password at build time?
- full disk encryption
  - initramfs support
  - hardware key support

### Hardware support
- sata
- pcie
- nvme/m.2
- emmc install & booting
- hdmi (?) not a high priority


TODO:
1) test sata: DONE
2) test pcie: DONE
3) test m.2: DONE
4) test usb: DONE
5) test fan controller: DONE
6) test emmc install & boot
   - worked!
     - installer should
       - write out the proper partitions
       - install uboot
       - copy over boot partition
       - update boot/extlinux/extlinux.conf to use emmc
       - copy over rootfs
       - update etc/fstab
       - other install steps (ssh keys, encrypted storage, etc)
7) start looking at uboot
  - TODO: test putting the device into maskrom mode
    - we might be able to boot from an sd card with stock uboot in the right location if we break the emmc uboot?
    - need to better understand how the rk3588 bootrom looks for boot devices, check in the sdk docs
      - section "Boot from SD/TF Card" https://opensource.rock-chips.com/wiki_Boot_option
        looks promising
        it describes the location of the u-boot-tpl and spl
        I found the spl on the emmc, located before the uboot partition
        cant find the tpl, maybe the idbloader.img is getting used instead?
        don't see an idbloader.img or miniloader for the rk3588 in the sdk tree?
  - TODO: investigate uboot verified boot
  - TODO: able to boot uboot from sdcard image, build tooling is complete, now need to actually get uboot working
    - start looking at the changes

TODO: do we need 
CONFIG_ROCKCHIP_EARLY_DISTRO_DTB_PATH="rk-kernel.dtb"
is it reading the rk-kernel.dtb from the emmc? How to test this? Look at logs?
similar for
config EMBED_KERNEL_DTB_PATH

excluded 
config ROCKCHIP_FIT_IMAGE
for now because I *don't* think we need it


config SPL_SERIAL_SUPPORT is now SPL_SERIAL
CONFIG_SPL_MMC_SUPPORT is now SPL_MMC


# Remote initramfs access
- want to support decrypting the rootfs over ssh or with hardware key
- need way to bake ssh public keys into initrafs when using encryption
  - put authorized keys in /boot
  - ensure that the port used for initramfs ssh is *not* available outside your network
  - make sure you have a password on your private key


# Fan issues

the cooling-levels of the fan don't seem to be properly changing with the trips/temps
```
cat /sys/class/thermal/cooling_device0/cur_state
```
stays at 0
even when
```
cat /sys/class/thermal/thermal_zone0/temp
```
goes over a temp trip, defined in the dtsi soc_thermal table


Model: MMC Y2P128 (sd/mmc)
Disk /dev/mmcblk0: 125GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name        Flags
 1      8389kB  12.6MB  4194kB               uboot
 2      12.6MB  16.8MB  4194kB               misc
 3      16.8MB  285MB   268MB   ext4         emmcboot    legacy_boot
 4      285MB   125GB   125GB   ext4         emmcrootfs



# installation script
- partition emmc
- setup encryption
- copy over uboot image
- copy over boot partition
  - modify extlinux to use emmcrootfs as boot target
- copy over rootfs

TODO: rewrite install script, make it automatable

```

sudo bash

TARGET=/dev/mmcblk0
BOOT_DEVICE=/dev/mmcblk2
ROOT_PARTITION=/dev/mmcblk0p3

mkdir -p /tmproot
mkdir -p /tmpboot

umount /tmpboot || true
umount /tmproot || true

parted --script $TARGET mklabel gpt
# make a 4MB uboot partition
parted --script $TARGET mkpart uboot 16384s 24575s
# make a roughly 200MB boot partition
parted --script $TARGET mkpart emmcboot 24576s 417791s
parted --script $TARGET set 2 legacy_boot on
# use the rest for rootfs
parted --script $TARGET mkpart emmcrootfs 417792s 100%

# mkfs, label the boot partition
# zero out the start to avoid mkfs asking if we really want to overwrite
dd if=/dev/zero of=${TARGET}p2 bs=512 count=1k
mkfs.ext4 -L emmcboot ${TARGET}p2

# write the uboot partition
dd if=/dev/zero of=${TARGET}p1 bs=512 count=8192
dd if=${BOOT_DEVICE}p1 of=${TARGET}p1

# copy over the boot partition, update extlinux.conf entry
mount ${TARGET}p2 /tmpboot
cp -a /boot/* /tmpboot
sed -i 's/DEV=sdcard/DEV=emmc/g' /tmpboot/extlinux/extlinux.conf
umount ${TARGET}p2

#START CRYPTO

#TODO review cryptsetup options used

CRYPTO=true
# manually supply -i 15000 for security at the cost of a slightly slower unlock
echo "Enter the password you would like to use to unlock the encrypted root partition at boot"
cryptsetup -q -y -s 512 luksFormat -i 15000 $ROOT_PARTITION
echo "Now unlock the newly created encrypted root partition so we can mount it and install the filesystem"
cryptsetup luksOpen $ROOT_PARTITION luksroot
ROOT_PARTITION=/dev/mapper/luksroot

#generate initrd host keys
ssh-keygen -q -t ed25519 -f /boot/ssh/ssh_host_ed25519_key -C "" -N ""
#TODO discourage use weak crypto keys
ssh-keygen -q -t rsa -f /boot/ssh/ssh_host_rsa_key -C "" -N ""

#TODO user must provide authorized_keys file, or pubkey to make sure they can
#unlock the initramfs

#END CRYPTO

# mkfs, label the rootfs partition
# zero out the start to avoid mkfs asking if we really want to overwrite
dd if=/dev/zero of=${ROOT_PARTITION} bs=512 count=1k
mkfs.ext4 -q -L emmcrootfs ${ROOT_PARTITION}

# copy over the rootfs partition, update fstab
mount ${ROOT_PARTITION} /tmproot
echo Syncing live root filesystem with new root filesystem, this will take about 4 minutes...
rsync -ah --info=progress2 --info=name0 --numeric-ids -x / /tmproot

# update fstab
sed -i 's/PARTLABEL=sdrootfs/PARTLABEL=emmcrootfs/g' /tmproot/etc/fstab
sed -i 's/PARTLABEL=sdboot/PARTLABEL=emmcboot/g' /tmproot/etc/fstab

umount ${ROOT_PARTITION}
echo Running fsck
e2fsck -p -f ${ROOT_PARTITION}

if [[ $CRYPTO == "true" ]]
then
# unmount and close encrypted storage
# let things settle, otherwise cryptsetup complainssss
    sleep 2
    cryptsetup luksClose luksroot
fi
```

TODO: initramfs has different mac addr than os??

# storage setup script

## Why not zfs native encryption?
```
Its lacking maturity, heres a sampling of encryption related failures and data loss issues:
https://github.com/openzfs/zfs/issues/12439
https://github.com/openzfs/zfs/issues/12270
https://github.com/openzfs/zfs/issues/12014
https://github.com/openzfs/zfs/issues/11679
and theres more...
even a zfs dev has said its not ready https://openzfs.topicbox.com/groups/developer/T86620b1082ed947a/would-anyone-be-able-to-help-with-11679
```

- layers
 - encryption
 - raid
 - btrfs

- cache ssd? https://www.kernel.org/doc/html/latest/admin-guide/bcache.html

- backup boot drive to storage?


Option 1:
- luks on each drive
- btrfs raid10 on the luks drives

PROS:
- btrfs is aware of the hardware layout, so can
  auto correct from copy
- 50% of storage is usable

CONS:
- writes have to be encrypted 4 times, each chunk for each device
- have to unlock all 4 drives seperately at boot
- can handle 1 drive failure

Option 2:
- mdadm raid 10
- luks on mdadm raid
- btrfs on luks

PROS:
- one encrypted volume
 - theoretically more efficient
 - simpler encryption setup
- can handle 2 drive failures
- 50% of storage is usable

CONS:
- btrfs is unaware of layout, so cannot auto correct from copy

The most important differentiators are:
- 1 vs 2 drive failures
- bitrot autocorrection

drive failure is more rare than bitrot, we assume the user has backups,
this is not intended for "production" environments where uptime is important
so going read-only due to 1 drive failure is not a huge issue
manually restoring bitrotted files from backups is annoying

Option(1) seems like the best way to go

https://gist.github.com/MaxXor/ba1665f47d56c24018a943bb114640d7

# cryptosetup options choices

```
sudo cryptsetup benchmark
# Tests are approximate using memory only (no storage IO).
PBKDF2-sha1       557160 iterations per second for 256-bit key
PBKDF2-sha256    1030035 iterations per second for 256-bit key
PBKDF2-sha512     418092 iterations per second for 256-bit key
PBKDF2-ripemd160  280968 iterations per second for 256-bit key
PBKDF2-whirlpool  129262 iterations per second for 256-bit key
argon2i       4 iterations, 544612 memory, 4 parallel threads (CPUs) for 256-bit key (requested 2000 ms time)
argon2id      4 iterations, 563665 memory, 4 parallel threads (CPUs) for 256-bit key (requested 2000 ms time)
#     Algorithm |       Key |      Encryption |      Decryption
        aes-cbc        128b       448.7 MiB/s       784.6 MiB/s
    serpent-cbc        128b               N/A               N/A
    twofish-cbc        128b        50.9 MiB/s        52.3 MiB/s
        aes-cbc        256b       365.4 MiB/s       657.3 MiB/s
    serpent-cbc        256b               N/A               N/A
    twofish-cbc        256b        50.9 MiB/s        52.3 MiB/s
        aes-xts        256b       640.6 MiB/s       640.8 MiB/s
    serpent-xts        256b               N/A               N/A
    twofish-xts        256b        51.4 MiB/s        51.5 MiB/s
        aes-xts        512b       561.2 MiB/s       561.2 MiB/s
    serpent-xts        512b               N/A               N/A
    twofish-xts        512b        51.4 MiB/s        51.5 MiB/s
```

# Encrypted storage setup
```

# create key file
#TODO Don't actually do this, only for testing
# TODO instead of using a key file, can we create a temporary password/fido key file to use for decrytion of all drives?
KEYFILE=/home/prawn/cryptkey
dd bs=64 count=1 if=/dev/urandom of=$KEYFILE iflag=fullblock
chmod 600 $KEYFILE

DRIVE1=/dev/sda
DRIVE2=/dev/sdb
DRIVE3=/dev/sdc
DRIVE4=/dev/sdd

TODO: test key size 512 vs 256 in full raid
# encrypt the devices
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE1 $KEYFILE
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE2 $KEYFILE
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE3 $KEYFILE
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE4 $KEYFILE


# backup the luks headers
DRIVE1_HEADER=/home/prawn/$(basename ${DRIVE1}).header.bak
DRIVE2_HEADER=/home/prawn/$(basename ${DRIVE2}).header.bak
DRIVE3_HEADER=/home/prawn/$(basename ${DRIVE3}).header.bak
DRIVE4_HEADER=/home/prawn/$(basename ${DRIVE4}).header.bak

sudo cryptsetup luksHeaderBackup --header-backup-file $DRIVE1_HEADER $DRIVE1
sudo cryptsetup luksHeaderBackup --header-backup-file $DRIVE2_HEADER $DRIVE2
sudo cryptsetup luksHeaderBackup --header-backup-file $DRIVE3_HEADER $DRIVE3
sudo cryptsetup luksHeaderBackup --header-backup-file $DRIVE4_HEADER $DRIVE4

# decrypt the drives

DRIVE1_DM=$(basename ${DRIVE1})_dm
DRIVE2_DM=$(basename ${DRIVE2})_dm
DRIVE3_DM=$(basename ${DRIVE3})_dm
DRIVE4_DM=$(basename ${DRIVE4})_dm

sudo cryptsetup open --key-file=$KEYFILE --type luks $DRIVE1 $DRIVE1_DM
sudo cryptsetup open --key-file=$KEYFILE --type luks $DRIVE2 $DRIVE2_DM
sudo cryptsetup open --key-file=$KEYFILE --type luks $DRIVE3 $DRIVE3_DM
sudo cryptsetup open --key-file=$KEYFILE --type luks $DRIVE4 $DRIVE4_DM

# Create the btrfs raid fs
#TODO add btrfs-progs package to base server image
sudo mkfs.btrfs -m raid10 -d raid10 /dev/mapper/${DRIVE1_DM} /dev/mapper/${DRIVE2_DM} /dev/mapper/${DRIVE3_DM} /dev/mapper/${DRIVE4_DM}
```


# remote testing
- valid image on sd card and mmc
- default boots to sd card
- ctrl-c on uboot over serial to boot to mmc instead


## uboot, boot sd card
sysboot mmc 1:2 any 0x00500000 /extlinux/extlinux.conf

## uboot, boot mmc
sysboot mmc 0:2 any 0x00500000 /extlinux/extlinux.conf


# tamper resistance
- have systemd service watching the state of the servers network
- possible things to check for:
  - external networking
  - router configuration
  - network public ip
  - specific local ips
  - accelerometer/physical sensors?
  - more?

if tamper check fails, lock the storage drives
if state is bad enough, possibly lock the root drive as well?

# sata errors during mkfs.btrfs

```
[  235.174523] ata1.01: failed to read SCR 1 (Emask=0x40)
[  235.174987] ata1.02: failed to read SCR 1 (Emask=0x40)
[  235.175449] ata1.03: failed to read SCR 1 (Emask=0x40)
[  235.175911] ata1.04: failed to read SCR 1 (Emask=0x40)
[  235.176372] ata1.05: failed to read SCR 1 (Emask=0x40)
[  235.176833] ata1.06: failed to read SCR 1 (Emask=0x40)
[  235.177335] ata1.07: failed to read SCR 1 (Emask=0x40)
[  235.177798] ata1.08: failed to read SCR 1 (Emask=0x40)
[  235.178259] ata1.09: failed to read SCR 1 (Emask=0x40)
[  235.178720] ata1.10: failed to read SCR 1 (Emask=0x40)
[  235.179182] ata1.11: failed to read SCR 1 (Emask=0x40)
[  235.179642] ata1.12: failed to read SCR 1 (Emask=0x40)
[  235.180103] ata1.13: failed to read SCR 1 (Emask=0x40)
[  235.180600] ata1.14: failed to read SCR 1 (Emask=0x40)
[  235.181068] ata1.00: exception Emask 0x100 SAct 0x2600 SErr 0x0 action 0x6 frozen
[  235.181738] ata1.00: failed command: WRITE FPDMA QUEUED
[  235.182205] ata1.00: cmd 61/40:48:e0:88:00/00:00:00:00:00/40 tag 9 ncq dma 32768 out
[  235.182205]          res 40/00:01:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.183552] ata1.00: status: { DRDY }
[  235.183910] ata1.00: failed command: WRITE FPDMA QUEUED
[  235.184377] ata1.00: cmd 61/20:50:00:a8:00/00:00:00:00:00/40 tag 10 ncq dma 16384 out
[  235.184377]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.185730] ata1.00: status: { DRDY }
[  235.186063] ata1.00: failed command: READ FPDMA QUEUED
[  235.186522] ata1.00: cmd 60/08:68:00:90:00/00:00:00:00:00/40 tag 13 ncq dma 4096 in
[  235.186522]          res 40/00:01:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.187880] ata1.00: status: { DRDY }
[  235.188215] ata1.01: exception Emask 0x100 SAct 0x80000000 SErr 0x0 action 0x6 frozen
[  235.188915] ata1.01: failed command: READ FPDMA QUEUED
[  235.189374] ata1.01: cmd 60/08:f8:48:fc:ff/00:00:74:05:00/40 tag 31 ncq dma 4096 in
[  235.189374]          res 40/00:01:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.190733] ata1.01: status: { DRDY }
[  235.191067] ata1.02: exception Emask 0x100 SAct 0x20 SErr 0x0 action 0x6 frozen
[  235.191719] ata1.02: failed command: READ FPDMA QUEUED
[  235.192177] ata1.02: cmd 60/08:28:00:82:00/00:00:00:00:00/40 tag 5 ncq dma 4096 in
[  235.192177]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.193505] ata1.02: status: { DRDY }
[  235.193862] ata1.03: exception Emask 0x100 SAct 0x960000 SErr 0x0 action 0x6 frozen
[  235.194555] ata1.03: failed command: READ FPDMA QUEUED
[  235.195015] ata1.03: cmd 60/10:88:28:80:00/00:00:00:00:00/40 tag 17 ncq dma 8192 in
[  235.195015]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.196351] ata1.03: status: { DRDY }
[  235.196685] ata1.03: failed command: READ FPDMA QUEUED
[  235.197161] ata1.03: cmd 60/30:90:48:80:00/00:00:00:00:00/40 tag 18 ncq dma 24576 in
[  235.197161]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.198507] ata1.03: status: { DRDY }
[  235.198841] ata1.03: failed command: READ FPDMA QUEUED
[  235.199320] ata1.03: cmd 60/78:a0:88:80:00/00:00:00:00:00/40 tag 20 ncq dma 61440 in
[  235.199320]          res 40/00:01:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.200687] ata1.03: status: { DRDY }
[  235.201022] ata1.03: failed command: READ FPDMA QUEUED
[  235.201480] ata1.03: cmd 60/f8:b8:08:81:00/00:00:00:00:00/40 tag 23 ncq dma 126976 in
[  235.201480]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[  235.202832] ata1.03: status: { DRDY }
[  236.467263] ata1.15: SATA link up 6.0 Gbps (SStatus 133 SControl 300)
[  236.544363] ata1.00: hard resetting link
[  236.858018] ahci fe210000.sata: FBS is disabled
[  237.017292] ahci fe210000.sata: FBS is enabled
[  237.018843] ata1.00: SATA link up 6.0 Gbps (SStatus 133 SControl 330)
[  237.019541] ata1.01: hard resetting link
[  237.334618] ahci fe210000.sata: FBS is disabled
[  237.493948] ahci fe210000.sata: FBS is enabled
[  237.494830] ata1.01: SATA link up 6.0 Gbps (SStatus 133 SControl 330)
[  237.495454] ata1.02: hard resetting link
[  237.808308] ahci fe210000.sata: FBS is disabled
[  237.967288] ahci fe210000.sata: FBS is enabled
[  237.968265] ata1.02: SATA link up 6.0 Gbps (SStatus 133 SControl 330)
[  237.968890] ata1.03: hard resetting link
[  238.281699] ahci fe210000.sata: FBS is disabled
[  238.440541] ahci fe210000.sata: FBS is enabled
[  238.441428] ata1.03: SATA link up 6.0 Gbps (SStatus 133 SControl 330)
[  238.751671] ahci fe210000.sata: FBS is disabled
[  238.910621] ahci fe210000.sata: FBS is enabled
[  238.911520] ata1.04: SATA link up 6.0 Gbps (SStatus 133 SControl 330)
[  239.221995] ata1.05: SATA link down (SStatus 0 SControl 330)
[  239.535313] ata1.06: SATA link down (SStatus 0 SControl 330)
[  239.852640] ata1.07: SATA link down (SStatus 0 SControl 330)
[  240.168850] ata1.08: SATA link down (SStatus 0 SControl 330)
[  240.485690] ata1.09: SATA link down (SStatus 0 SControl 330)
[  240.801974] ata1.10: SATA link down (SStatus 0 SControl 330)
[  241.118926] ata1.11: SATA link down (SStatus 0 SControl 330)
[  241.435384] ata1.12: SATA link down (SStatus 0 SControl 330)
[  241.752367] ata1.13: SATA link down (SStatus 0 SControl 330)
[  242.065420] ata1.14: SATA link down (SStatus 0 SControl 330)
[  242.069930] ata1.00: configured for UDMA/133
[  242.091660] ata1.01: configured for UDMA/133
[  242.100799] ata1.02: configured for UDMA/133
[  242.104943] ata1.03: configured for UDMA/133
[  242.106985] ata1.04: configured for UDMA/133
[  242.107535] ata1.02: device reported invalid CHS sector 0
[  242.108037] ata1.00: device reported invalid CHS sector 0
[  242.108533] ata1.03: device reported invalid CHS sector 0
[  242.109038] ata1.03: device reported invalid CHS sector 0
[  242.109638] ata1.03: device reported invalid CHS sector 0
[  242.110164] sd 0:2:0:0: [sdc] tag#5 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.111091] sd 0:2:0:0: [sdc] tag#5 Sense Key : 0x5 [current]
[  242.111617] sd 0:2:0:0: [sdc] tag#5 ASC=0x21 ASCQ=0x4
[  242.112084] sd 0:2:0:0: [sdc] tag#5 CDB: opcode=0x88 88 00 00 00 00 00 00 00 82 00 00 00 00 08 00 00
[  242.112891] I/O error, dev sdc, sector 33280 op 0x0:(READ) flags 0x80700 phys_seg 1 prio class 0
[  242.113772] sd 0:0:0:0: [sda] tag#13 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.114638] sd 0:0:0:0: [sda] tag#13 Sense Key : 0x5 [current]
[  242.115170] sd 0:0:0:0: [sda] tag#13 ASC=0x21 ASCQ=0x4
[  242.115641] sd 0:0:0:0: [sda] tag#13 CDB: opcode=0x88 88 00 00 00 00 00 00 00 90 00 00 00 00 08 00 00
[  242.116454] I/O error, dev sda, sector 36864 op 0x0:(READ) flags 0x80700 phys_seg 1 prio class 0
[  242.117316] sd 0:3:0:0: [sdd] tag#17 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.118180] sd 0:3:0:0: [sdd] tag#17 Sense Key : 0x5 [current]
[  242.118712] sd 0:3:0:0: [sdd] tag#17 ASC=0x21 ASCQ=0x4
[  242.119183] sd 0:3:0:0: [sdd] tag#17 CDB: opcode=0x88 88 00 00 00 00 00 00 00 80 28 00 00 00 10 00 00
[  242.119997] I/O error, dev sdd, sector 32808 op 0x0:(READ) flags 0x80700 phys_seg 2 prio class 0
[  242.120842] sd 0:3:0:0: [sdd] tag#18 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.121707] sd 0:3:0:0: [sdd] tag#18 Sense Key : 0x5 [current]
[  242.122238] sd 0:3:0:0: [sdd] tag#18 ASC=0x21 ASCQ=0x4
[  242.122709] sd 0:3:0:0: [sdd] tag#18 CDB: opcode=0x88 88 00 00 00 00 00 00 00 80 48 00 00 00 30 00 00
[  242.123521] I/O error, dev sdd, sector 32840 op 0x0:(READ) flags 0x80700 phys_seg 6 prio class 0
[  242.124362] sd 0:3:0:0: [sdd] tag#20 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.125227] sd 0:3:0:0: [sdd] tag#20 Sense Key : 0x5 [current]
[  242.125758] sd 0:3:0:0: [sdd] tag#20 ASC=0x21 ASCQ=0x4
[  242.126229] sd 0:3:0:0: [sdd] tag#20 CDB: opcode=0x88 88 00 00 00 00 00 00 00 80 88 00 00 00 78 00 00
[  242.127042] I/O error, dev sdd, sector 32904 op 0x0:(READ) flags 0x80700 phys_seg 5 prio class 0
[  242.127882] sd 0:3:0:0: [sdd] tag#23 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.128746] sd 0:3:0:0: [sdd] tag#23 Sense Key : 0x5 [current]
[  242.129277] sd 0:3:0:0: [sdd] tag#23 ASC=0x21 ASCQ=0x4
[  242.129748] sd 0:3:0:0: [sdd] tag#23 CDB: opcode=0x88 88 00 00 00 00 00 00 00 81 08 00 00 00 f8 00 00
[  242.130590] I/O error, dev sdd, sector 33032 op 0x0:(READ) flags 0x80700 phys_seg 14 prio class 0
[  242.131423] sd 0:1:0:0: [sdb] tag#31 UNKNOWN(0x2003) Result: hostbyte=0x00 driverbyte=DRIVER_OK cmd_age=37s
[  242.132287] sd 0:1:0:0: [sdb] tag#31 Sense Key : 0x5 [current]
[  242.132818] sd 0:1:0:0: [sdb] tag#31 ASC=0x21 ASCQ=0x4
[  242.133290] sd 0:1:0:0: [sdb] tag#31 CDB: opcode=0x88 88 00 00 00 00 05 74 ff fc 48 00 00 00 08 00 00
[  242.134130] I/O error, dev sdb, sector 23437769800 op 0x0:(READ) flags 0x80700 phys_seg 1 prio class 0
[  242.134978] ata1: EH complete
[  242.690748] BTRFS: device fsid aad3c285-7360-4bc0-9837-3b41218cb8db devid 1 transid 5 /dev/mapper/sda_dm scanned by mkfs.btrfs (1153)
[  242.692327] BTRFS: device fsid aad3c285-7360-4bc0-9837-3b41218cb8db devid 2 transid 5 /dev/mapper/sdb_dm scanned by mkfs.btrfs (1153)
[  242.693807] BTRFS: device fsid aad3c285-7360-4bc0-9837-3b41218cb8db devid 3 transid 5 /dev/mapper/sdc_dm scanned by mkfs.btrfs (1153)
[  242.695350] BTRFS: device fsid aad3c285-7360-4bc0-9837-3b41218cb8db devid 4 transid 5 /dev/mapper/sdd_dm scanned by mkfs.btrfs (1153)```

whats up with these
Incompat features:  extref, skinny-metadata
