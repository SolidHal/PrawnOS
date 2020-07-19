#!/bin/bash

set -x
set -e

# build Linux-libre, with ath9k_htc firmware and initramfs built in


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2018-2020 Hal Emmerich <hal@halemmerich.com>

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
    echo "No resources directory"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No build directory supplied"
    exit 1
fi
if [ -z "$4" ]
then
    echo "No PrawnOS initramfs supplied"
    exit 1
fi
if [ -z "$" ]
then
    echo "No PrawnOS target arch supplied"
    exit 1
fi

KVER=$1
RESOURCES=$2
BUILD_DIR=$3
INITRAMFS=$4
TARGET=$5


ARCH_ARMHF=armhf
ARCH_ARM64=arm64

cd $BUILD_DIR
make mrproper

if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    CROSS_COMPILER=arm-none-eabi-
    # kernel doesn't differentiate between arm and armhf
    ARCH=arm
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    CROSS_COMPILER=aarch64-linux-gnu-
    ARCH=$ARCH_ARM64
else
    echo "no valid target arch specified"
fi

#copy in the resources, initramfs
cp $INITRAMFS .
cp $RESOURCES/config .config
cp $RESOURCES/kernel.its .
make -j $(($(nproc) +1))  CROSS_COMPILE=$CROSS_COMPILER ARCH=$ARCH zImage modules dtbs
mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack vmlinux.kpart \
              --version 1 \
              --vmlinuz vmlinux.uimg \
              --arch arm \
              --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
              --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
              --config $RESOURCES/cmdline \
              --bootloader bootloader.bin

RESULT=$?
if [ ! $RESULT -eq 0 ]; then
    rm -f vmlinux.kpart
fi
