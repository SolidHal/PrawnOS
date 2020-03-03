#!/bin/bash

#See the block of "echos" in main() for description of this script

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
BOOT_DEVICE=$(mount | head -n 1 | cut -d '2' -f 1)

main() {
    echo "---------------------------------------------------------------------------------------------------------------------"
    echo "PrawnOS Install or Expand Script"
    echo "Installation sets up the internal emmc partitions, root encryption, and copies the filesystem from the"
    echo "current boot device to the target device. The target device cannot be the current boot device"
    echo
    echo "Expansion simply targets the booted device, and expands the filesystem to fill the entire thing instead of just 2GB."
    echo "Because of this, root encryption cannot be setup"
    echo
    echo "For installation, this script can be quit and re-ran at any point."
    echo "Unfortunately for expansion this is not the case"
    echo "---------------------------------------------------------------------------------------------------------------------"
    echo
    echo "Expand or Install?: "
    echo "The currently booted device is ${BOOT_DEVICE}"
    while true; do
        read -p "[I]nstall or [E]xpand?" IE
        case $IE in
            [Ii]* ) install; break;;
            [Ee]* ) expand; break;;
            * ) echo "Please answer I or E";;
        esac
    done
}

#Now to pick the install target: internal, sd, or usb
#if target is usb, and boot device is usb, target is sdb
#and whether to enable crypto
install() {
    echo "Pick an install target. This can be the Internal Emmc, an SD card, or a USB device"
    echo "Please ensure you have only have the booted device and the desired target device inserted."
    echo "The currently booted device is ${BOOT_DEVICE}"
    while true; do
        read -p "[I]nternal Emmc, [S]D card, or [U]SB device?: " ISU
        case $ISU in
            [Ii]* ) TARGET=/dev/mmcblk2p; break;;
            [Ss]* ) TARGET=/dev/mmcblk0p; break;;
            [Uu]* ) TARGET=USB; break;;
            * ) echo "Please answer I, S, or U";;
        esac
    done
    if [[ $TARGET == "USB" ]]
    then
        if [[ $BOOT_DEVICE == "/dev/sda" ]]
        then
            TARGET=/dev/sdb
        else
            TARGET=/dev/sda
        fi
    fi
    if [[ $TARGET == $BOOT_DEVICE ]]
    then
        echo "Can't install to booted device, please ensure you have *only* the booted device and target device inserted"
        exit
    fi

    #cut off the "p" if we are using an sd card or internal emmc, doesn't change TARGET if we are using usb
    TARGET_NO_P=$(echo $TARGET | cut -d 'p' -f 1)
    if [ ! -e $TARGET_NO_P ];
    then
        echo "${TARGET_NO_P} does not exist, have you plugged in your target sd card or usb device?"
        exit 1
    fi

    #Now on to the installation, basically copy InstallToInternal.sh
    while true; do
        read -p "This will ERASE ALL DATA ON ${TARGET_NO_P} and reboot when finished, do you want to continue? [y/N]" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done

    umount ${TARGET}1 || /bin/true
    umount ${TARGET}2 || /bin/true

    if [[ $TARGET == "/dev/mmcblk2p" ]]
    then
        emmc_partition
    else
        external_partition $TARGET_NO_P
    fi

    KERNEL_PARTITION=${TARGET}1
    ROOT_PARTITION=${TARGET}2
    CRYPTO=false

    echo Writing kernel partition
    dd if=/dev/zero of=$KERNEL_PARTITION bs=512 count=65536
    dd if=${BOOT_DEVICE}1 of=$KERNEL_PARTITION conv=notrunc

    #Handle full disk encryption
    echo "Would you like to setup full disk encrytion using LUKs/DmCrypt?"
    select yn in "Yes" "No"
    do
        case $yn,$REPLY in
        Yes,*|*,Yes )
            CRYPTO=true
            # Since iteration count is based on cpu power, and the rk3288 isn't as fast as a usual
            # desktop cpu, manually supply -i 15000 for security at the cost of a slightly slower unlock
            dmesg -n 2
            echo "Enter the password you would like to use to unlock the encrypted root partition at boot"
            cryptsetup -q -y -s 512 luksFormat -i 15000 $ROOT_PARTITION || exit 1
            echo "Now unlock the newly created encrypted root partition so we can mount it and install the filesystem"
            cryptsetup luksOpen $ROOT_PARTITION luksroot || exit 1
            dmesg -n 7
            ROOT_PARTITION=/dev/mapper/luksroot
            break
            ;;
        No,*|*,No )
            break
            ;;
        * )
            echo "Invalid Option, please enter Yes or No, 1 or 2"
            ;;
        esac
    done

    echo Writing Filesystem, this will take about 4 minutes...
    mkfs.ext4 -F -b 1024 $ROOT_PARTITION
    INSTALL_MOUNT=/mnt/install_mount
    mkdir -p $INSTALL_MOUNT/
    mount $ROOT_PARTITION $INSTALL_MOUNT/
    rsync -ah --info=progress2 --info=name0 --numeric-ids -x / $INSTALL_MOUNT/
    #Remove the live-fstab and install a base fstab
    rm $INSTALL_MOUNT/etc/fstab
    echo "${ROOT_PARTITION} / ext4 defaults,noatime 0 1" > $INSTALL_MOUNT/etc/fstab

    while true; do
        read -p "Install a desktop environment and the supporting packages? [Y/n]" ins
        case $ins in
            [Yy]* ) install_packages $INSTALL_MOUNT; break;;
            [Nn]* ) break;;
            * ) echo "Please answer y or n";;
        esac
    done
    umount $ROOT_PARTITION
    echo Running fsck
    e2fsck -p -f $ROOT_PARTITION
    if [[ $CRYPTO == "true" ]]
    then
        # unmount and close encrypted storage
        # let things settle, otherwise cryptsetup complainssss
        sleep 2
        cryptsetup luksClose luksroot
    fi
    echo "Please remove the booted device after power off is complete"
    while true; do
        read -p "Reboot? [y/N]" re
        case $re in
            [Yy]* ) reboot;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done

}

#Setup partition map on internal emmc
emmc_partition() {
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    dmesg -D
    echo Writing partition map to internal emmc
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
}

#Setup partition map for external bootable device, aka usb or sd card
external_partition() {
    EXTERNAL_TARGET=$1
    kernel_start=8192
    kernel_size=65536
    root_start=$(($kernel_start + $kernel_size))
    #wipe the partition map, cgpt doesn't like anything weird in the primary or backup partition maps
    sgdisk -Z $EXTERNAL_TARGET
    partprobe $EXTERNAL_TARGET
    #make the base gpt partition map
    parted --script $EXTERNAL_TARGET mklabel gpt
    cgpt create $EXTERNAL_TARGET
    #must use cgpt to make the kernel partition, as we need the -S, -T, and -P variables
    cgpt add -i 1 -t kernel -b $kernel_start -s $kernel_size -l Kernel -S 1 -T 5 -P 10 $EXTERNAL_TARGET
    #Now the main filesystem
    #cgpt doesn't seem to handle this part correctly
    sgdisk -N 2 $EXTERNAL_TARGET
    #Set the type to "data"
    sgdisk -t 2:0700 $EXTERNAL_TARGET
    #Name it "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root $EXTERNAL_TARGET
    #Reload the partition mapping
    partprobe $EXTERNAL_TARGET
}

#simply expand to fill the current boot device
expand() {
    if [[ $BOOT_DEVICE == "/dev/mmcblk2" ]]
    then
        echo "Can't expand to fill internal emmc, install will have done this already"
        exit
    fi
    #Make the boot partition fille the whole drive
    #Delete the partition
    sgdisk -d 2 $BOOT_DEVICE
    #Make new partition map entry, with full size
    sgdisk -N 2 $BOOT_DEVICE
    #Set the type to "data"
    sgdisk -t 2:0700 $BOOT_DEVICE
    #Name it "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root $BOOT_DEVICE
    #Reload the partition mapping
    partprobe $BOOT_DEVICE
    #Force the filesystem to fill the new partition
    resize2fs -f ${BOOT_DEVICE}2
    echo "/dev/${BOOT_DEVICE}2 / ext4 defaults,noatime 0 1" > /etc/fstab
    while true; do
        read -p "Install a desktop environment and the supporting packages? [Y/n]" ins
        case $ins in
            [Yy]* ) /InstallResources/InstallPackages.sh; reboot;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done


}

#Install all packages, desktop environment to target device
install_packages() {
    TARGET_MOUNT=$1
    echo "Installing Packages"
    mount -t proc proc $TARGET_MOUNT/proc/
    mount --rbind /sys $TARGET_MOUNT/sys/
    mount --rbind /dev $TARGET_MOUNT/dev/
    chroot $TARGET_MOUNT/ ./InstallResources/InstallPackages.sh
    umount $TARGET_MOUNT/proc/
    mount --make-rprivate /sys
    mount --make-rprivate /dev
    umount -R $TARGET_MOUNT/sys/
    umount -R $TARGET_MOUNT/dev/

}


#call the main function, script technically starts here
#Organized this way so that main can come before the functions it calls
main "$@"; exit
