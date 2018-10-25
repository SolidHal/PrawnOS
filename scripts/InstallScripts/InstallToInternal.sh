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
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    dmesg -D
    echo Writing partition map
    sfdisk /dev/mmcblk2 < $RESOURCES/mmc.partmap
    dmesg -E
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
