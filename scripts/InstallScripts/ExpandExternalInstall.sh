#!/bin/bash

#Expand PrawnOS to fill the entire external device

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

while true; do
    echo "This script will expand PrawnOS to fill the entire external"
    echo " storage device it is booted from"
    echo "If installing to a USB flash drive, make sure only one USB storage device is plugged in"
    read -p "install to: internal external (S)D, external (U)SB Storage: " ESU
    case $ESU in
        [Ss]* ) TARGET=SD; break;;
        [Uu]* ) TARGET=USB; break;;
        * ) echo "Please answer S or U";;
    esac
done


if [ "$TARGET" = "USB" ]
then
    #Make the boot partition fille the whole drive
    #Delete the partition
    sgdisk -d 2 /dev/sda
    #Make new partition map entry, with full size
    sgdisk -N 2 /dev/sda
    #Set the type to "data"
    sgdisk -t 2:0700 /dev/sda
    #Name is "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root /dev/sda
    #Reload the partition mapping
    partprobe /dev/sda
    #Force the filesystem to fill the new partition
    resize2fs -f /dev/sda2
fi

if [ "$TARGET" = "SD" ]
then
    #Make the boot partition fille the whole drive
    #Delete the partition
    sgdisk -d 2 /dev/mmcblk0
    #Make new partition map entry, with full size
    sgdisk -N 2 /dev/mmcblk0
    #Set the type to "data"
    sgdisk -t 2:0700 /dev/mmcblk0
    #Name is "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root /dev/mmcblk0
    #Reload the partition mapping
    partprobe /dev/mmcblk0
    #Force the filesystem to fill the new partition
    resize2fs -f /dev/mmcblk0p2
fi
