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


if [ -z "$1" ]
then
    echo "No base file system image supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No initramfs resources dir supplied"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No output location supplied"
    exit 1
fi
BASE=$1
RESOURCES=$2
OUT_DIR=$3
TARGET=$4



ARCH_ARMHF=armhf
ARCH_ARM64=arm64

outmnt=$(mktemp -d -p "$(pwd)")
outdev=$(losetup -f)

if [ ! -f $BASE ]
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

function chroot_get_libs
{
    set +e
    set -x
    [ $# -lt 2 ] && return

    dest=$1
    shift
    for i in "$@"
    do
        # Get an absolute path for the file
        [ "${i:0:1}" == "/" ] || i=$(which $i)
        # Skip files that already exist at target.
        [ -f "$dest/$i" ] && continue
        if [ -e "$i" ]
        then
            # Create destination path
            d=`echo "$i" | grep -o '.*/'` &&
                mkdir -p "$dest/$d" &&
                # Copy file
                cat "$i" > "$dest/$i" &&
                chmod +x "$dest/$i"
        else
            echo "Not found: $i"
        fi
        # Recursively copy shared libraries' shared libraries.
        chroot_get_libs "$dest" $(ldd "$i" | egrep -o '/.* ')
    done
}

trap cleanup INT TERM EXIT

[ ! -d build ] && mkdir build

losetup -P $outdev $BASE
#mount the root filesystem
mount -o noatime ${outdev}p2 $outmnt

#make a skeleton filesystem
initramfs_src=$outmnt/etc/prawnos/initramfs_src
initramfs_src_direct=/etc/prawnos/initramfs_src
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

mknod $initramfs_src/dev/console c 5 1
mknod $initramfs_src/dev/null c 1 3
mknod $initramfs_src/dev/tty c 5 0
mknod $initramfs_src/dev/urandom c 1 9
mknod $initramfs_src/dev/random c 1 8
mknod $initramfs_src/dev/zero c 1 5


#install the few tools we need, and the supporting libs
initramfs_binaries='/bin/busybox /sbin/cryptsetup /sbin/blkid'

#do so **automatigically**
export -f chroot_get_libs
export initramfs_binaries
export initramfs_src_direct

chroot $outmnt /bin/bash -c "chroot_get_libs $initramfs_src_direct $initramfs_binaries"

#have to add libgcc manually since ldd doesn't see it as a requirement :/
armhf_libs=arm-linux-gnueabihf
arm64_libs=aarch64-linux-gnu
if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    LIBS_DIR=$armhf_libs
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    LIBS_DIR=$arm64_libs
else
    echo "no valid target arch specified"
    exit 1
fi
cp $outmnt/lib/$LIBS_DIR/libgcc_s.so.1 $initramfs_src/lib/$LIBS_DIR/

#add the init script
cp $RESOURCES/initramfs-init $initramfs_src/init
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
find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $OUT_DIR/PrawnOS-initramfs.cpio.gz

# cleanup
cd $OUT_DIR
rm -rf $initramfs_src

