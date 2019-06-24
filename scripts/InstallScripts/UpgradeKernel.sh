
#!/bin/bash

#Replace the PrawnOS linux kernel that is installed on the internal emmc storage with
#the PrawnOS linux kernel from the booted usb device or sd card


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


read -p "This will replace the kernel installed on the internal storage (EMMC) with the one on the booted USB drive or SD card and reboot when finished, do you want to continue? [Y/n]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    echo Writing kernel partition
    dd if="$BOOT_DEVICE"1 of=/dev/mmcblk2p1


fi

echo Exiting
