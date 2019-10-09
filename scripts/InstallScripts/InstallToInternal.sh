#!/bin/bash

#Install PrawnOS to the internal emmc, this will partition the internal emmc
#and erase ALL data on it


# This file is part of PrawnOS (http://www.prawnos.com)
# Copyright (c) 2018 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.

RESOURCES=/InstallResources
# Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk0 for an sd card
BOOT_DEVICE=$(mount | head -n 1 | cut -d '3' -f 1)

echo "--------------------------------------------------------------------------------------------------------"
echo "PrawnOS Install To Internal Emmc Script"
echo "Sets up the internal emmc partitions, root encryption, and copies the filesystem from the bootable media"
echo "This script can be quit and re-ran at any point"
echo "--------------------------------------------------------------------------------------------------------"
read -p "This will ERASE ALL DATA ON THE INTERNAL STORAGE (EMMC) and reboot when finished, do you want to continue? [y/N]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    dmesg -D
    umount /dev/mmcblk2p1 || /bin/true
    umount /dev/mmcblk2p2 || /bin/true
    umount /dev/mmcblk2p3 || /bin/true

    echo Writing partition map
    DISK_SZ="$(blockdev --getsz /dev/mmcblk2)"
    echo Total disk size is: $DISK_SZ
    if [ $DISK_SZ = 30785536 ]
    then
        echo Detected Emmc Type 1
        sfdisk /dev/mmcblk2 < $RESOURCES/mmc.partmap

    elif [ $DISK_SZ = 30777344 ]
    then
        echo Detected Emmc Type 2
        sfdisk /dev/mmcblk2 < $RESOURCES/mmc_type2.partmap
    else
        echo ERROR! Not a known EMMC type, please open an issue on github or send SolidHal an email with the Total disk size reported above
        echo Try a fallback value? This will allow installation to continue, at the cost of a very small amoutnt of disk space. This may not work.
        select yn in "Yes" "No"
        do
            case $yn,$REPLY in
                Yes,*|*,Yes )
                    echo Trying Emmc Type 2
                    sfdisk /dev/mmcblk2 < $RESOURCES/mmc_type2.partmap
                    break
                    ;;
                * )
                    echo "Invalid Option, please enter Yes or No, 1 or 2"
                    ;;
            esac
        done
    fi
    dmesg -E

    echo Writing kernel partition
    dd if=/dev/zero of=/dev/mmcblk2p1 bs=512 count=65536
    dd if="$BOOT_DEVICE"1 of=/dev/mmcblk2p1

    BOOT_DEV_NAME=mmcblk2p2
    ROOT_DEV_NAME=mmcblk2p3
    CRYPTO=false

    #ready /boot
    mkfs.ext4 -F -b 1024 /dev/$BOOT_DEV_NAME
    mkdir -p /mnt/boot
    mount /dev/$BOOT_DEV_NAME /mnt/boot

    #Handle full disk encryption
    echo "Would you like to setup full disk encrytion using LUKs/DmCrypt?"
    select yn in "Yes" "No"
    do
        case $yn,$REPLY in
        Yes,*|*,Yes )
            CRYPTO=true
            # Since iteration count is based on cpu power, and the rk3288 isn't as fast as a usual
            # desktop cpu, manually supply -i 15000 for security at the cost of a slightly slower unlock
            echo "Now enter the password you would like to use to unlock the encrypted root partition at boot"
            cryptsetup -q -y -s 512 luksFormat -i 15000 /dev/$ROOT_DEV_NAME
            echo "Now unlock the newly created encrypted root partition so we can mount it and install the filesystem"
            cryptsetup luksOpen /dev/$ROOT_DEV_NAME luksroot || exit 1
            ROOT_DEV_NAME=mapper/luksroot
            #set the root encryption flag
            touch /mnt/boot/root_encryption
            break
            ;;
        * )
            echo "Invalid Option, please enter Yes or No, 1 or 2"
            ;;
        esac
    done

    echo Writing Filesystem, this will take about 4 minutes...
    mkfs.ext4 -F -b 1024 /dev/$ROOT_DEV_NAME
    mkdir -p /mnt/mmc/
    mount /dev/$ROOT_DEV_NAME /mnt/mmc
    rsync -ah --info=progress2 --info=name0 --numeric-ids -x / /mnt/mmc/
    #Remove the live-fstab and install a base fstab
    rm /mnt/mmc/etc/fstab
    if [[ $CRYPTO == "true" ]]
    then
        echo "/dev/mappper/luksroot / ext4 defaults,noatime 0 1" > /mnt/mmc/etc/fstab
    else
        echo "/dev/mmcblk2p3 / ext4 defaults,noatime 0 1" > /mnt/mmc/etc/fstab
    fi
    umount /dev/$ROOT_DEV_NAME
    echo Running fsck
    e2fsck -p -f /dev/$ROOT_DEV_NAME
    if [[ $CRYPTO == "true" ]]
    then
        # unmount and close encrypted storage
        cryptsetup luksClose luksroot
    fi
    echo Rebooting... Please remove the usb drive once shutdown is complete
    reboot
fi

echo Exiting
