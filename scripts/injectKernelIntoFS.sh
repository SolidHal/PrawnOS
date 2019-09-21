#!/bin/sh -xe

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

if [ -z "$1" ]
then
    echo "No kernel version supplied"
    exit 1
fi
KVER=$1

if [ -z "$2" ]
then
    echo "No image filesystem image supplied"
    exit 1
fi
outmnt=$(mktemp -d -p `pwd`)
outdev=/dev/loop7

build_resources=resources/BuildResources

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

losetup -P $outdev $2
#mount the root filesystem
mount -o noatime ${outdev}p3 $outmnt
#mount the initramfs partition 
# mount -o noatime ${outdev}p2 $outmnt/boot

# put the kernel in the kernel partition, modules in /lib/modules and AR9271
# firmware in /lib/firmware
dd if=$build_resources/blank_kernel of=${outdev}p1 conv=notrunc
dd if=build/linux-$KVER/vmlinux.kpart of=${outdev}p1 conv=notrunc
make -C build/linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install

# put the required kernel items into the initramfs aka the device tree and the kernel image
# TODO: the in-place kernel upgrade script must be changed to copy in new versions of these files
# cp build/linux-$KVER/arch/arm/boot/dts/rk3288-veyron-speedy.dtb $outmnt/boot/rk3288-veyron-speedy.dtb
# cp build/linux-$KVER/vmlinux.kpart $outmnt/boot

#TODO: do we actually need the kernel in /boot?? I think not. lets test and find out

# the initramfs is build into the kernel image

# the ath9k firmware is built into the kernel image, so nothing else must be done

umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
