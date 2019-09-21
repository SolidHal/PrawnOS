
#!/bin/sh -xe

#Build initramfs image


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


outmnt=$(mktemp -d -p `pwd`)
outdev=/dev/loop7
KVER=$1
ROOT_DIR=`pwd`
build_resources=$ROOT_DIR/resources/BuildResources

if [ ! -f $ROOT_DIR/PrawnOS-*-c201-libre-2GB.img-BASE ]
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

losetup -P $outdev $ROOT_DIR/PrawnOS-*-c201-libre-2GB.img-BASE
#mount the root filesystem
mount -o noatime ${outdev}p3 $outmnt
#mount the initramfs partition 
mount -o noatime ${outdev}p2 $outmnt/boot

#make a skeleton filesystem
initramfs_src=$outmnt/InstallResources/initramfs_src
rm -rf $initramfs_src*
mkdir -p $initramfs_src
mkdir $initramfs_src/bin
mkdir $initramfs_src/dev
mkdir $initramfs_src/etc
mkdir $initramfs_src/newroot
mkdir $initramfs_src/proc
mkdir $initramfs_src/sys
mkdir $initramfs_src/sbin
mkdir $initramfs_src/run
mkdir $initramfs_src/lib
mkdir $initramfs_src/lib/arm-linux-gnueabihf

#install the few tools we need, and the supporting libs
cp $outmnt/bin/busybox $outmnt/sbin/cryptsetup $initramfs_src/bin/
cp $outmnt/lib/arm-linux-gnueabihf/libblkid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/
cp $outmnt/lib/arm-linux-gnueabihf/libuuid.so.1 $initramfs_src/lib/arm-linux-gnueabihf/
cp $outmnt/lib/arm-linux-gnueabihf/libc.so.6 $initramfs_src/lib/arm-linux-gnueabihf/

cp $outmnt/lib/ld-linux-armhf.so.3 $initramfs_src/lib/
cp $outmnt/sbin/blkid $initramfs_src/bin/

#add the init script
cp $build_resources/initramfs-init $initramfs_src/init
chmod +x $initramfs_src/init

#compress and install
rm -rf $outmnt/boot/PrawnOS-initramfs.cpio.gz
cd $initramfs_src
ln -s busybox bin/cat
ln -s busybox bin/mount
ln -s busybox bin/sh
ln -s busybox bin/switch_root
ln -s busybox bin/umount
find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $outmnt/boot/PrawnOS-initramfs.cpio.gz 

cd $ROOT_DIR

[ ! -d build ] && mkdir build
cd build
# store for kernel building
cp $outmnt/boot/PrawnOS-initramfs.cpio.gz .
