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

if [ -z "$1" ]
then
    echo "No kernel version supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No filesystem image supplied"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No target arch supplied"
    exit 1
fi
if [ -z "$4" ]
then
    echo "No kernel build path supplied"
    exit 1
fi
if [ -z "$5" ]
then
    echo "No kernel package path supplied"
    exit 1
fi
if [ -z "$6" ]
then
    echo "No kernel package name supplied"
    exit 1
fi
if [ -z "$7" ]
then
    echo "No kernel package debian supplied"
    exit 1
fi


KVER=$1
OUTNAME=$2
TARGET=$3
KERNEL_BUILD=$4
KERNEL_PACKAGE_PATH=$5
KERNEL_PACKAGE_NAME=$6
KERNEL_PACKAGE_DEB=$7



ARCH_ARMHF=armhf
ARCH_ARM64=arm64
#this arch nonsense is obnoxious.
# armhf is just "arm" to the kernel and vbutil,
# arm64 is what the kernel uses, but aarch64 is what vbutil uses
if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    # kernel doesn't differentiate between arm and armhf
    KERNEL_ARCH=arm
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    KERNEL_ARCH=$ARCH_ARM64
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

#Mount the build filesystem image

losetup -P $outdev $OUTNAME
#mount the root filesystem
mount -o noatime ${outdev}p2 $outmnt

# put the kernel in the kernel partition, modules in /lib/modules and AR9271
# firmware in /lib/firmware
kernel_size=65536
#blank the kernel partition first, with of zeros
#this is very very important, not doing this or using the incorrect kernel size can lead to very strange and difficult to debug issues
dd if=/dev/zero of=${outdev}p1 conv=notrunc bs=512 count=$kernel_size
#now write the new kernel
dd if=$KERNEL_BUILD/vmlinux.kpart of=${outdev}p1

#install the kernel image package to the chroot so it can be updated by apt later
#need to do funky things to avoid running the postinst script that dds the kernel to the kernel partition
#maybe it would make more sense to run this on install, but then a usb booting device couldn't upgrade its kernel
cp $KERNEL_PACKAGE_PATH/$KERNEL_PACKAGE_DEB $outmnt/
chroot $outmnt dpkg --unpack /$KERNEL_PACKAGE_DEB
chroot $outmnt rm /var/lib/dpkg/info/$KERNEL_PACKAGE_NAME.postinst
chroot $outmnt dpkg --configure $KERNEL_PACKAGE_NAME
chroot $outmnt rm /$KERNEL_PACKAGE_DEB

#install the kernel modules and headers
#we dont make any modules yet
# make -C build/$TARGET/linux-$KVER ARCH=$KERNEL_ARCH INSTALL_MOD_PATH=$outmnt modules_install
make -C $KERNEL_BUILD ARCH=$KERNEL_ARCH INSTALL_HDR_PATH=$outmnt/usr/src/linux-$KVER-gnu headers_install
# the ath9k firmware is built into the kernel image, so nothing else must be done

umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
