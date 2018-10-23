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

read -p "This will ERASE ALL DATA ON THE INTERNAL STORAGE (EMMC) and reboot when finished, do you want to continue? [Y/n]" -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo Writing partitions
    #Wipe the partition tables
    sgdisk -o -Z /dev/mmcblk2
    # Make new partition table
    sgdisk -g /dev/mmcblk2
    #Get the last usable sector, cant just take last sector as we depend on the secondary gpt
    MAX_SIZE="$(sgdisk -p /dev/mmcblk2 | grep -o 'last usable sector is.*' | awk '{print $5}')"
    # Make new entries
    cgpt add -i 1 -b 20480 -s 65536 -t kernel -l KERNEL -S 1 -T 5 -P 10 /dev/mmcblk2
    cgpt add -i 2 -b 86016 -s $MAX_SIZE -t data -l Root /dev/mmcblk2
    echo Writing kernel partition
    dd if=/dev/sda1 of=/dev/mmcblk2p1
    echo Writing Filesystem, this will take about 4 minutes...
    dd if=/dev/sda2 of=/dev/mmcblk2p2 bs=50M
    echo Expanding Filesystem
    e2fsck -p -f /dev/mmcblk2p2
    resize2fs /dev/mmcblk2p2
    echo Rebooting... Please remove the usb drive once shutdown is complete
    reboot
fi

echo Exiting
