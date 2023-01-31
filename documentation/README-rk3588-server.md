
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
- backup with borg backup

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

TMPBOOT=/tmpboot
TMPROOT=/tmproot

mkdir -p $TMPROOT
mkdir -p $TMPBOOT

umount $TMPBOOT || true
umount $TMPROOT || true

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
mount ${TARGET}p2 $TMPBOOT
cp -a /boot/* $TMPBOOT
sed -i 's/DEV=sdcard/DEV=emmc/g' ${TMPBOOT}/extlinux/extlinux.conf

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
mkdir -p ${TMPBOOT}/ssh
ssh-keygen -q -t ed25519 -f ${TMPBOOT}/ssh/ssh_host_ed25519_key -C "" -N ""
#TODO discourage use weak crypto keys
#ssh-keygen -q -t rsa -f ${TMPBOOT}/ssh/ssh_host_rsa_key -C "" -N ""

#TODO user must provide authorized_keys file, or pubkey to make sure they can
#unlock the initramfs
# must put the authorized keys file in boot/ssh/ on the emmc aka $TMPBOOT/ssh
# just copy it from home dir for now
cp /home/prawn/authorized_keys ${TMPBOOT}/ssh/authorized_keys
chmod 600 ${TMPBOOT}/ssh/authorized_keys
umount ${TARGET}p2

#END CRYPTO

# mkfs, label the rootfs partition
# zero out the start to avoid mkfs asking if we really want to overwrite
dd if=/dev/zero of=${ROOT_PARTITION} bs=512 count=1k
mkfs.ext4 -q -L emmcrootfs ${ROOT_PARTITION}

# copy over the rootfs partition, update fstab
mount ${ROOT_PARTITION} $TMPROOT
echo Syncing live root filesystem with new root filesystem, this will take about 4 minutes...
rsync -ah --info=progress2 --info=name0 --numeric-ids -x / $TMPROOT

# update fstab
sed -i 's/PARTLABEL=sdrootfs/PARTLABEL=emmcrootfs/g' ${TMPROOT}/etc/fstab
sed -i 's/PARTLABEL=sdboot/PARTLABEL=emmcboot/g' ${TMPROOT}/etc/fstab

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
    # Tests are approximate using memory only (no storage IO).
PBKDF2-sha1       566185 iterations per second for 256-bit key
PBKDF2-sha256    1040253 iterations per second for 256-bit key
PBKDF2-sha512     420102 iterations per second for 256-bit key
PBKDF2-ripemd160  284013 iterations per second for 256-bit key
PBKDF2-whirlpool  127750 iterations per second for 256-bit key
argon2i       4 iterations, 531695 memory, 4 parallel threads (CPUs) for 256-bit key (requested 2000 ms time)
argon2id      4 iterations, 560031 memory, 4 parallel threads (CPUs) for 256-bit key (requested 2000 ms time)
#     Algorithm |       Key |      Encryption |      Decryption
        aes-cbc        128b       447.6 MiB/s       781.1 MiB/s
    serpent-cbc        128b        31.7 MiB/s        35.3 MiB/s
    twofish-cbc        128b        51.0 MiB/s        52.3 MiB/s
        aes-cbc        256b       364.8 MiB/s       654.4 MiB/s
    serpent-cbc        256b        31.7 MiB/s        35.3 MiB/s
    twofish-cbc        256b        51.1 MiB/s        52.2 MiB/s
        aes-xts        256b       639.4 MiB/s       638.9 MiB/s
    serpent-xts        256b        31.7 MiB/s        35.0 MiB/s
    twofish-xts        256b        51.3 MiB/s        51.4 MiB/s
        aes-xts        512b       560.0 MiB/s       559.8 MiB/s
    serpent-xts        512b        31.8 MiB/s        35.0 MiB/s
    twofish-xts        512b        51.4 MiB/s        51.4 MiB/s
```

picking aes-xts with 512b key due to speed/security

# Encrypted storage setup
## Now actually encrypt

```
DRIVE1=/dev/sda
DRIVE2=/dev/sdb
DRIVE3=/dev/sdc
DRIVE4=/dev/sdd

# encrypt the devices
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE1
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE2
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE3
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE4


# backup the luks headers
#TODO provide suggestions for header storage
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

sudo cryptsetup open --type luks $DRIVE1 $DRIVE1_DM
sudo cryptsetup open --type luks $DRIVE2 $DRIVE2_DM
sudo cryptsetup open --type luks $DRIVE3 $DRIVE3_DM
sudo cryptsetup open --type luks $DRIVE4 $DRIVE4_DM

# Create the btrfs raid fs
sudo mkfs.btrfs -m raid10 -d raid10 /dev/mapper/${DRIVE1_DM} /dev/mapper/${DRIVE2_DM} /dev/mapper/${DRIVE3_DM} /dev/mapper/${DRIVE4_DM}

# mount the btrfs fs
sudo mkdir -p /mnt/data
sudo mount -t btrfs -o defaults,noatime /dev/mapper/${DRIVE1_DM} /mnt/data

#TODO now install the btrfs scan systemd service
```

## Recover on device failure

mount degraded
if `${DRIVE1_DM}` is the missing device, use any of `${DRIVE#_DM}`
```
mount -t btrfs -o defaults,noatime,degraded /dev/mapper/${DRIVE1_DM} /mnt/data
```

locate the device id of the missing disk
```
btrfs device usage /mnt/data
```

ex output:
```
/dev/mapper/data1, ID: 1
   Device size:             7.28TiB
   Device slack:              0.00B
   Data,RAID1:              5.46TiB
   Metadata,RAID1:          7.00GiB
   System,RAID1:           32.00MiB
   Unallocated:             1.81TiB

missing, ID: 2
   Device size:             7.28TiB
   Device slack:              0.00B
   Data,RAID1:              5.46TiB
   Metadata,RAID1:          7.00GiB
   System,RAID1:           32.00MiB
   Unallocated:             1.81TiB
```

so for this example, missing device is ID 2

```
MISSING_ID=2
```

setup encryption on the new device
```
DRIVE#=/dev/<new-device>
sudo cryptsetup --verify-passphrase --cipher aes-xts-plain64 --hash sha512 --key-size 512 --iter-time 5000 luksFormat $DRIVE# $KEYFILE
```

backup the new header
```
DRIVE#_HEADER=/home/prawn/$(basename ${DRIVE#}).header.bak
sudo cryptsetup luksHeaderBackup --header-backup-file $DRIVE#_HEADER $DRIVE#
```

decrypt the device
```
DRIVE#_DM=$(basename ${DRIVE#})_dm
sudo cryptsetup open --key-file=$KEYFILE --type luks $DRIVE# $DRIVE#_DM
```

start btrfs replace
```
btrfs replace start $MISSING_ID /dev/mapper/${DRIVE#_DM} /mnt/data
```

check replace status
```
btrfs replace status /mnt/data
```


## btrfs maintence task

`/etc/systemd/system/btrfs-scrub.timer`

```
[Unit]
Description=Monthly scrub btrfs filesystem, verify block checksums
Documentation=man:btrfs-scrub

[Timer]
# first saturday each month
OnCalendar=Sat *-*-1..7 3:00:00
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/btrfs-scrub.service`

```
[Unit]
Description=Scrub btrfs filesystem, verify block checksums
Documentation=man:btrfs-scrub

[Service]
Type=simple
ExecStart=/bin/btrfs scrub start -Bd /mnt/data
KillSignal=SIGINT
IOSchedulingClass=idle
CPUSchedulingPolicy=idle
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

# sata errors
can recreate issue seen on mdadm/btrfs raid by doing
```
sudo dcfldd if=/dev/urandom of=/dev/sda1 of=/dev/sdb1 count=100000
```

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
......
```

What isn't to blame:
- ncq, tried libata.force=noncq

to try:
- 2 drives instead of 4
  - same issue
  - observe same issue with mode "single"
- 1 drive
  - can't recreate issue, even when mkfs.btrfs only targets 1 disk while multiple are installed in system
- 2 drives without backplane
  - same issue
  - observe same issue with mode "single"

- different sata cables
  - same issue
- pcie sata card
- look at sata patches in kernel tree
- what if we don't use luks?
  - sudo mkfs.btrfs -f -m single -d single /dev/sda /dev/sdb
- recreate with mdadm?
  - recreated issue 
- simpler recreation
  - recreated by writing a random 2GB file to 2 drives
  - sudo dcfldd if=/dev/urandom of=/dev/sda1 of=/dev/sdb1 count=100000
    - froze at
      45568 blocks (1424Mb) written.
      and started throwing the kernel errors



There is one patch on the ata driver, which reads:

```
    ATA: ahci_platform: enable FBS for RK3588

    Because the CAP parameters of AHCI are incorrect, FBS cannot
    be started automatically and needs to be configured manually.
    This configuration can improve the read-write performance
    when connecting multiple SATA hard disks through the PM chip.

    Signed-off-by: Yifeng Zhao <yifeng.zhao@rock-chips.com>
    Change-Id: I66ff92dce1711e3d189801c8caa3219217a50dda
```
PM is the port multiplier

this page has a good overview of port multipliers, and FBS https://www.synopsys.com/designware-ip/technical-bulletin/port-multipliers.html
seems if we don't have fbs enabled, cbs is used instead, which is slower.

our boards uses sata0 behind the port multiplier
```
/* sata pm */
&combphy0_ps {
	status = "okay";
};

&sata0 {
	status = "okay";
};

&vcc_sata_pwr_en{
	status = "okay";
	gpio = <&pca9555 PCA_IO1_2 GPIO_ACTIVE_HIGH>;  //PCA_IO 12
};
```

```
	sata0: sata@fe210000 {
		compatible = "rockchip,rk-ahci", "snps,dwc-ahci";
		reg = <0 0xfe210000 0 0x1000>;
		clocks = <&cru ACLK_SATA0>, <&cru CLK_PMALIVE0>,
			 <&cru CLK_RXOOB0>, <&cru CLK_PIPEPHY0_REF>,
			 <&cru CLK_PIPEPHY0_PIPE_ASIC_G>;
		clock-names = "sata", "pmalive", "rxoob", "ref", "asic";
		interrupts = <GIC_SPI 273 IRQ_TYPE_LEVEL_HIGH>;
		interrupt-names = "hostc";
		phys = <&combphy0_ps PHY_TYPE_SATA>;
		phy-names = "sata-phy";
		ports-implemented = <0x1>;
		status = "disabled";
	};
```


```
prawn@PrawnOS:~$ sudo dmesg | rg "sata"
[    0.786092] ahci fe210000.sata: Looking up ahci-supply from device tree
[    0.786100] ahci fe210000.sata: Looking up ahci-supply property in node /sata@fe210000 failed
[    0.786114] ahci fe210000.sata: supply ahci not found, using dummy regulator
[    0.786786] ahci fe210000.sata: Looking up phy-supply from device tree
[    0.786791] ahci fe210000.sata: Looking up phy-supply property in node /sata@fe210000 failed
[    0.786799] ahci fe210000.sata: supply phy not found, using dummy regulator
[    0.787529] ahci fe210000.sata: Looking up target-supply from device tree
[    0.787535] ahci fe210000.sata: Looking up target-supply property in node /sata@fe210000 failed
[    0.787543] ahci fe210000.sata: supply target not found, using dummy regulator
[    0.788251] ahci fe210000.sata: forcing port_map 0x0 -> 0x1
[    0.788756] ahci fe210000.sata: AHCI 0001.0300 32 slots 1 ports 6 Gbps 0x1 impl platform mode
[    0.789503] ahci fe210000.sata: flags: ncq sntf pm led clo only pmp fbs pio slum part ccc apst
[    0.790272] ahci fe210000.sata: port 0 can do FBS, forcing FBSCP
[    1.551145] vcc_sata_pwr_en: no parameters, enabled
[    1.551338] reg-fixed-voltage vcc-sata-pwr-en-regulator: vcc_sata_pwr_en supplying 0uV
[    7.252448] ahci fe210000.sata: FBS is enabled
[    7.888629] ahci fe210000.sata: FBS is disabled
[   11.560592] ahci fe210000.sata: FBS is enabled
[   12.192102] ahci fe210000.sata: FBS is disabled
[   12.350579] ahci fe210000.sata: FBS is enabled
```

### Solved
FBS was to blame

#TODO
- document btrfs drive failure recovery
- add ssd cache support?
- add maintence systemd service/timer for btrfs scrubbing
- finalize the install script, and the storage setup script



### Using fido2 keys with luks
add stuff for fido2 luks
backports.list
```
deb http://deb.debian.org/debian bullseye-backports main
```
```
apt -t bullseye-backports install systemd
```

so we can use this to enroll a device:
```
sudo systemd-cryptenroll --fido2-with-client-pin=yes --fido2-with-user-presence=yes --fido2-device=auto /dev/sda
```

and this to decrypt a device

```
sudo /usr/lib/systemd/systemd-cryptsetup attach sda_dm /dev/sda - fido2-device=auto
```

TODO
- but we have to set the pin using another fido2 too, like pynitrokey/nitropy (maybe theres a better, more general tool to use here?)
- also, decrypting seems to give up if there are multiple fido2 keys enrolled, which isn't great.
  this might be fixed in a newer version of systemd?

options:
- figure out how to enroll and use 2 fido2 keys, even if usage is annoying
  - also have recovery key
  - recovery key format: large random string (stored securely) + memorized, unrecorded portion
- only use one fido2 key, and instead have only the recovery key as backup



### Install server software

```
sudo apt install samba
```

can't get docker from debian, because of this warning:
```
Using docker.io on non-amd64 hosts is not supported at this time. Please be careful when using it on anything besides amd64. 
```
instead follow https://docs.docker.com/engine/install/debian/#prerequisites

