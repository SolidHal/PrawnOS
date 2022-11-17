#!/bin/bash

set -e

#installs the specified bootloader image onto the currently booted device


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2022 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


# function die():
# print an error message and exit with the provided code
# $1 = error message
# $2 = exit code
die()
{
    redtxt='\033[0;31m'
    printf "$redtxt$1\n"
    exit $2
}

# returns the full path to the emmc device, in the form /dev/mmcblk#
get_emmc_devname() {
    local devname=$(find /dev -name "mmcblk*boot0" | sed "s/boot0//")
    if [ -z "$devname" ]; then
        echo "Unknown device! can't determine emmc devname. Please file an issue with the output of fdisk -l if you get this on a supported device"
        exit 1
    fi
    echo $devname
}

# returns the full path to the sd card device, in the form /dev/mmcblk#
get_sd_devname() {
    local emmc=$(get_emmc_devname)
    devname=$(find /dev -name "mmcblk*" ! -iwholename "*${emmc}*" ! -name "*mmcblk*p*")

    if [ -z "$devname" ]
    then
        echo "Unknown device! can't determine sd devname. Please file an issue with the output of fdisk -l if you get this on a supported device"; exit 1;
    fi
    echo $devname
}


# function get_root_partition()
# print the actual physical device
# currently mounted as "/"
get_root_partition()
{
    rootfs=$(findmnt / -n -o SOURCE)

    if echo "$rootfs" | grep -q "/dev/mapper" ;then
	     # root filesystem is on luks volume
	     # let's find the physical device behind it
	     rootfs=$(cryptsetup status "$rootfs" | grep "device: " | cut -d ' ' -f 5)
    fi
       echo "$rootfs"
}


# Check root or sudo
[ ! $(id -u) = 0 ] &&
    die "Please run this script with sudo, or as root" 1

if [ -z "$1" ]
then
    echo "No bootloader image supplied"
    exit 1
fi

emmc_devname=$(get_emmc_devname)
pnum_bootloader=1
bootloaderimg=$1
rootfs=$(get_root_partition)
devname=$(lsblk -no pkname $rootfs | head -n 1)
devtype=
bpart=


case "$devname" in
    $emmc_devname)
	      devtype="Internal emmc"
	      bpart=/dev/${devname}p$pnum_bootloader
	      ;;
    mmcblk[0-9])
	      devtype="External SD card"
	      bpart=/dev/${devname}p$pnum_bootloader
        ;;
    *)
	      die "FAILED to recognize booted device type $devname" 127
esac


# Check that the needed bootloader images exist
[ ! -e "$bootloaderimg" ] &&
    die "ERROR: cannot find bootloader image at $bootloaderimg !" 127


# Prompt for user's confirmation
echo "
----------------------------
 /!\\ !!! CAUTION !!! /!\\
----------------------------
This will flash a new bootloader image onto the running device's bootloader partition: $bpart
The detected running boot device is: $devtype.
DO NOT shutdown or reboot before completing the process!
"

printf "%s" "Do you want to continue? [y/N] "

read ans


[ "$ans" != "y" ] &&
    [ "$ans" != "Y" ] &&
    die "Aborted by user. Bootloader partition unchanged." 1


# put the bootloader in bootloader partition
#blank the bootloader partition first, with 4194kB of zeros
bootloader_size=8192
block_size=512
dd if=/dev/zero of="$bpart" conv=notrunc bs=512 count=$bootloader_size ||
    die "FAILED to flash blank bootloader on $bpart!" 255

dd if="$bootloaderimg" of="$bpart" conv=notrunc ||
    die "FAILED to flash bootloader image on $bpart!" 255

echo "
The new bootloader image has been successfully flashed onto $bpart.
Reboot to run the new bootloader"
