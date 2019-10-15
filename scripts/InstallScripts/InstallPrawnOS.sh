#!/bin/bash

#Install PrawnOS to the desired device. This will wipe the device, enable root encryption if desired and
#copy the kernel and filesystem to the 


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

main() {

    RESOURCES=/InstallResources
    # Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk0 for an sd card
    BOOT_DEVICE=$(mount | head -n 1 | cut -d '2' -f 1)

    echo "Expand or Install?"
    echo "Expand in place to fill the entire booted external device"
    echo "Install to another internal or external device besides the one we are booted from"
    echo "Installation allow for root encryption to be setup, but must target a external or internal device other than the currently booted device"
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
        read -p "[I]nternal Emmc, [S]D card, or [U]SB device?" ISU
        case $IE in
            [Ii]* ) $TARGET=/dev/mmcblk2; break;;
            [Ss]* ) $TARGET=/dev/mmcblk0; break;;
            [Uu]* ) $TARGET=USB; break;;
            * ) echo "Please answer I, S, or U";;
        esac
    done

    if [[ $TARGET == "USB" ]]
    then
        if [[ $BOOT_DEVICE == "/dev/sda" ]]
        then
            $TARGET=/dev/sdb
        else
            $TARGET=/dev/sda
        fi
    fi
    if [[ $TARGET == $BOOT_DEVICE ]]
    then
        echo "Can't install to booted device, please ensure you have only have the booted device and one single other inserted"
        exit
    fi

    #Now on to the installation, basically copy InstallToInternal.sh

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
    resize2fs -f ${BOOT_DEVICE}p2
    echo "/dev/${BOOT_DEVICE}p2 / ext4 defaults,noatime 0 1" > /etc/fstab

}


#call the main function, script technically starts here
main "$@"; exit
