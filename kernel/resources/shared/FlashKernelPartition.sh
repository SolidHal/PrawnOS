#!/bin/bash

#installs the specified kernel image onto the currently booted device


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2020 Hal Emmerich <hal@halemmerich.com>
# Copyright (c) 2020 Fil Bergamo <fil@filberg.eu>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


### SHARED CONST AND VARS
device_veyron_speedy="Google Speedy"
device_veyron_minnie="Google Minnie"
device_veyron_mickey="Google Mickey"
device_gru_kevin="Google Kevin"
device_gru_bob="Google Bob"

get_device() {
    local device=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
    echo $device
}

get_emmc_devname() {
    local devname=$(ls /dev/mmcblk* | grep -F boot0 | sed "s/boot0//" | cut -d / -f 3)
    if [ -z "$devname" ]; then
        echo "Unknown device! can't determine emmc devname. Please file an issue with the output of fdisk -l if you get this on a supported device"
        exit 1
    fi
    echo $devname
}

get_sd_devname() {
    local device=$(get_device)
    case "$device" in
        $device_veyron_speedy) local devname=mmcblk0;;
        $device_veyron_minnie) local devname=mmcblk0;;
        $device_veyron_mickey) local devname="";;
        $device_gru_kevin) local devname=mmcblk0;;
        $device_gru_bob) local devname=mmcblk0;;
        * ) echo "Unknown device! can't determine sd card devname. Please file an issue with the output of fdisk -l if you get this on a supported device"; exit 1;;
    esac
    echo $devname
}

### END SHARED CONST AND VARS

# -----------------------------------------------
#              STATIC CONFIGURATION
# -----------------------------------------------
#
# eMMC device name
emmc_devname=$(get_emmc_devname)
#
# GPT partition type UUID for "ChromeOS kernel"
ptype_kernel="FE3A2A5D-4F32-41A7-B725-ACCC3285A309"
#
# Kernel partition number
pnum_kernel=1
# -----------------------------------------------

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

# function get_partition_type_uuid()
# print the UUID of the gpt partition type
# for the given partition number on the given device
# $1 = device (e.g. /dev/mmcblk2)
# $2 = partition number
get_partition_type_uuid()
{
    cgpt show -i "$2" -t -n -q "$1" 2>/dev/null
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


# ------------- BEGIN SCRIPT EXECUTION --------------------

set -e

# Check root or sudo
[ ! $(id -u) = 0 ] &&
    die "Please run this script with sudo, or as root" 1

if [ -z "$1" ]
then
    echo "No kernel image supplied"
    exit 1
fi

kimg=$1

rootfs=$(get_root_partition)
devname=$(lsblk -no pkname $rootfs | head -n 1)
model=$(get_device)
devtype=
kpart=

case "$devname" in
    $emmc_devname)
	devtype="Internal eMMC"
	kpart=/dev/${devname}p$pnum_kernel
	;;
    sd*)
	devtype="USB Stick"
	kpart=/dev/${devname}$pnum_kernel
	;;
    mmcblk[0-9])
	devtype="External SD card"
	kpart=/dev/${devname}p$pnum_kernel
	;;
    *)
	die "FAILED to recognize booted device type $devname" 127
esac

# Check that the selected partition is effectively of type "kernel"
ptype=$(get_partition_type_uuid /dev/$devname $pnum_kernel)
[ ! "$ptype" = "$ptype_kernel" ] &&
    die "FATAL ERROR: unexpected partitioning scheme found. Partition # $pnum_kernel is NOT the kernel partition!" 255

# Check that the needed kernel images exist
[ ! -e "$kimg" ] &&
    die "ERROR: cannot find kernel image at $kimg !" 127


# Prompt for user's confirmation
echo "
----------------------------
 /!\\ !!! CAUTION !!! /!\\
----------------------------
This will flash a new kernel image onto the running device's kernel partition: $kpart
The detected running boot device is: $devtype.
The model you are running is: $model.
DO NOT shutdown or reboot before completing the process!
"

printf "%s" "Do you want to continue? [y/N] "

read ans

[ "$ans" != "y" ] &&
    [ "$ans" != "Y" ] &&
    die "Aborted by user. Kernel partition unchanged." 1

# put the kernel in the kernel partition
#blank the kernel partition first, with 32MiB of zeros
kernel_size=65536
block_size=512
dd if=/dev/zero of="$kpart" conv=notrunc bs=512 count=$kernel_size ||
    die "FAILED to flash blank kernel on $kpart!" 255

dd if="$kimg" of="$kpart" conv=notrunc ||
    die "FAILED to flash kernel image on $kpart!" 255

echo "
The new kernel image has been successfully flashed onto $kpart.
Reboot to run the new kernel"

# TODO: install modules. -----------------------------------
# Right now, there's no easy way to do that on the running machine
# -----------------------------------------------------------------
# make -C build/linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install
