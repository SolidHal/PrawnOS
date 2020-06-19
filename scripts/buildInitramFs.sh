#!/bin/bash

set -x
set -e

#Build initramfs image


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


outmnt=$(mktemp -d -p `pwd`)
outdev=/dev/loop7
if [ -z "$1" ]
then
    echo "No base file system image filename supplied"
    exit 1
fi
BASE=$1
ROOT_DIR=`pwd`
build_resources=$ROOT_DIR/resources/BuildResources

if [ ! -f $ROOT_DIR/$BASE ]
then
    echo "No base filesystem, run 'make filesystem' first"
    exit 1
fi

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

[ ! -d build ] && mkdir build

losetup -P $outdev $ROOT_DIR/$BASE
#mount the root filesystem
mount -o noatime ${outdev}p2 $outmnt

#make a skeleton filesystem
initramfs_src=$outmnt/InstallResources/initramfs_src
rm -rf $initramfs_src*
mkdir -p $initramfs_src
mkdir $initramfs_src/bin
mkdir $initramfs_src/dev
mkdir $initramfs_src/etc
mkdir $initramfs_src/newroot
mkdir $initramfs_src/boot
mkdir $initramfs_src/proc
mkdir $initramfs_src/sys
mkdir $initramfs_src/sbin
mkdir $initramfs_src/run
mkdir $initramfs_src/run/cryptsetup
mkdir $initramfs_src/lib
mkdir $initramfs_src/lib/arm-linux-gnueabihf

mknod -m 622 $initramfs_src/dev/console c 5 1
mknod -m 622 $initramfs_src/dev/tty c 4 0

#install the few tools we need, and the supporting libs
cp $outmnt/bin/busybox $outmnt/sbin/cryptsetup $initramfs_src/bin/
cp $outmnt/lib/arm-linux-gnueabihf/libblkid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/
cp $outmnt/lib/arm-linux-gnueabihf/libuuid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/
cp $outmnt/lib/arm-linux-gnueabihf/libc.so.6 $initramfs_src/lib/arm-linux-gnueabihf/

cp $outmnt/lib/ld-linux-armhf.so.3 $initramfs_src/lib/
cp $outmnt/sbin/blkid $initramfs_src/bin/

cp $outmnt/usr/lib/arm-linux-gnueabihf/libpopt.so.0 $initramfs_src/lib/arm-linux-gnueabihf/libpopt.so.0
cp $outmnt/usr/lib/arm-linux-gnueabihf/libssl.so.1.1 $initramfs_src/lib/arm-linux-gnueabihf/libssl.so.1.1
cp $outmnt/usr/lib/arm-linux-gnueabihf/libcrypto.so.1.1 $initramfs_src/lib/arm-linux-gnueabihf/libcrypto.so.1.1
cp $outmnt/usr/lib/arm-linux-gnueabihf/libargon2.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libargon2.so.1
cp $outmnt/usr/lib/arm-linux-gnueabihf/libjson-c.so.3 $initramfs_src/lib/arm-linux-gnueabihf/libjson-c.so.3

cp $outmnt/lib/arm-linux-gnueabihf/libm.so.6 $initramfs_src/lib/arm-linux-gnueabihf/libm.so.6
cp $outmnt/lib/arm-linux-gnueabihf/libcryptsetup.so.12 $initramfs_src/lib/arm-linux-gnueabihf/libcryptsetup.so.12
cp $outmnt/lib/arm-linux-gnueabihf/libuuid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libuuid.so.1
cp $outmnt/lib/arm-linux-gnueabihf/libblkid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libblkid.so.1
cp $outmnt/lib/arm-linux-gnueabihf/libc.so.6 $initramfs_src/lib/arm-linux-gnueabihf/libc.so.6
cp $outmnt/lib/ld-linux-armhf.so.3 $initramfs_src/lib/ld-linux-armhf.so.3
cp $outmnt/lib/arm-linux-gnueabihf/libdevmapper.so.1.02.1 $initramfs_src/lib/arm-linux-gnueabihf/libdevmapper.so.1.02.1
cp $outmnt/lib/arm-linux-gnueabihf/librt.so.1 $initramfs_src/lib/arm-linux-gnueabihf/librt.so.1
cp $outmnt/lib/arm-linux-gnueabihf/libdl.so.2 $initramfs_src/lib/arm-linux-gnueabihf/libdl.so.2
cp $outmnt/lib/arm-linux-gnueabihf/libselinux.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libselinux.so.1
cp $outmnt/lib/arm-linux-gnueabihf/libudev.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libudev.so.1
cp $outmnt/lib/arm-linux-gnueabihf/libpthread.so.0 $initramfs_src/lib/arm-linux-gnueabihf/libpthread.so.0
cp $outmnt/lib/arm-linux-gnueabihf/libpcre.so.3 $initramfs_src/lib/arm-linux-gnueabihf/libpcre.so.3
cp $outmnt/lib/arm-linux-gnueabihf/libgcc_s.so.1 $initramfs_src/lib/arm-linux-gnueabihf/libgcc_s.so.1
#add the init script
cp $build_resources/initramfs-init $initramfs_src/init
chmod +x $initramfs_src/init
cp $initramfs_src/init $initramfs_src/sbin/init

#compress and install
rm -rf $outmnt/boot/PrawnOS-initramfs.cpio.gz
cd $initramfs_src
ln -s busybox bin/cat
ln -s busybox bin/mount
ln -s busybox bin/sh
ln -s busybox bin/switch_root
ln -s busybox bin/umount

# store for kernel building
find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $ROOT_DIR/build/PrawnOS-initramfs.cpio.gz

