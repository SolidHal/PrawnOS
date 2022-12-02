
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

initramfs and root have different mac addresses, we can use this to
avoid every ssh session warning about host id changing

to go along with this, we should copy the existing host keys from the initramfs
when we install a new one
