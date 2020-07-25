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

KVER=$1
OUTNAME=$2
TARGET=$3
KERNEL_PACKAGE_PATH=$4
KERNEL_PACKAGE=$5

outmnt=$(mktemp -d -p "$(pwd)")
outdev=/dev/loop7

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
#blank the kernel partition first, with 32MiB of zeros
dd if=/dev/zero of=${outdev}p1 conv=notrunc bs=512 count=$kernel_size
#now write the new kernel
dd if=build/$TARGET/linux-$KVER/vmlinux.kpart of=${outdev}p1 conv=notrunc
# don't install modules for now
#make -C build/$TARGET/linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install

#install the kernel image package to the chroot so it can be updated by apt later
#need to do funky things to avoid running the postinst script that dds the kernel to the kernel partition
#maybe it would make more sense to run this on install, but then a usb booting device couldn't upgrade its kernel
#TODO uncomment and test once arm64 is done
# cp $KERNEL_PACKAGE_PATH $outmnt/
# chroot $outmnt dpkg --unpack $KERNEL_PACKAGE
# chroot $outmnt rm /var/lib/dpkg/info/$KERNEL_PACKAGE.postinst -f
# chroot $outmnt dpkg --configure $KERNEL_PACKAGE

# the ath9k firmware and initramfs is built into the kernel image, so nothing else must be done

umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
