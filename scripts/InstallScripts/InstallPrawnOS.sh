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

RESOURCES=/InstallResources
# Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk0 for an sd card
BOOT_DEVICE=$(mount | head -n 1 | cut -d '2' -f 1)

#The currently booted device is $BOOT_DEVICE


echo "Expand or Install?"
echo "Expand in place to fill the entire booted external device"
echo "Install to another internal or external device besides the one we are booted from"
echo "Installation allow for root encryption to be setup, but must target a external or internal device other than the currently booted device"
echo "The currently booted device is $BOOT_DEVICE"
while true; do
    read -p "[I]nstall or [E]xpand?" IE
    case $IE in
        [Ii]* ) METHOD=INSTALL; break;;
        [Ee]* ) METHOD=EXPAND; break;;
        * ) echo "Please answer I or E";;
    esac
done
