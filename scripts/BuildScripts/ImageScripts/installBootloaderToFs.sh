#!/bin/bash

set -x
set -e

# This file is part of PrawnOS (https://www.prawnos.com)
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


#Ensure Sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo, or as root:"
    echo "sudo $0 $*"
    exit 1
fi

if [ -z "$1" ]
then
    echo "No filesystem image supplied"
    exit 1
fi

if [ -z "$2" ]
then
    echo "No target arch supplied"
    exit 1
fi

if [ -z "$3" ]
then
    echo "No bootloader build path supplied"
    exit 1
fi

if [ -z "$4" ]
then
    echo "No bootloader package path supplied"
    exit 1
fi

if [ -z "$5" ]
then
    echo "No bootloader package name supplied"
    exit 1
fi

if [ -z "$6" ]
then
    echo "No bootloader package debian supplied"
    exit 1
fi


OUTNAME=$1
TARGET=$2
BOOTLOADER_BUILD=$3
BOOTLOADER_PACKAGE_PATH=$4
BOOTLOADER_PACKAGE_NAME=$5
BOOTLOADER_PACKAGE_DEB=$6

ARCH_ARMHF=armhf
ARCH_ARM64=arm64
if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    echo "armhf does not have a supported bootloader"
    exit 1
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    echo "arm64 does not have a supported bootloader"
    exit 1
elif [ "$TARGET" == "${ARCH_ARM64}-rk3588-server" ]; then
    BOOTLOADER=uboot
else
    echo "no valid target arch specified"
fi



outmnt=$(mktemp -d -p "$(pwd)")
outdev=$(losetup -f)

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is sometimes required to properly clean the loop devices and ensure a clean build
cleanup() {
    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1

    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1
}

trap cleanup INT TERM EXIT

losetup -P $outdev $OUTNAME

if [ "$BOOTLOADER" == "uboot" ]; then

    #mount the root filesystem
    mount -o noatime ${outdev}p3 $outmnt

    # put the bootloader in the bootloader partition
    bootloader_size=8192
    #blank the bootloader partition first, with of zeros
    #this is very very important, not doing this or using the incorrect bootloader size can lead to very strange and difficult to debug issues
    dd if=/dev/zero of=${outdev}p1 conv=notrunc bs=512 count=$bootloader_size
    #now write the new bootloader
    dd if=$BOOTLOADER_BUILD/uboot.img of=${outdev}p1

    #install the bootloader image package to the chroot so it can be updated by apt later
    #need to do funky things to avoid running the postinst script that dds the bootloader to the bootloader partition
    #maybe it would make more sense to run this on install, but then an sd card booting device couldn't upgrade its bootloader
    cp $BOOTLOADER_PACKAGE_PATH/$BOOTLOADER_PACKAGE_DEB $outmnt/
    chroot $outmnt dpkg --unpack /$BOOTLOADER_PACKAGE_DEB
    chroot $outmnt rm /var/lib/dpkg/info/$BOOTLOADER_PACKAGE_NAME.postinst
    chroot $outmnt dpkg --configure $BOOTLOADER_PACKAGE_NAME
    chroot $outmnt rm /$BOOTLOADER_PACKAGE_DEB

else
    echo "no valid target bootloader"
    exit 1
fi


umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
