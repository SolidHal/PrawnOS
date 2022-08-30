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

if [ -z "$1" ]; then
    echo "No kernel version supplied"
    exit 1
elif [ -z "$2" ]; then
    echo "No resources directory"
    exit 1
elif [ -z "$3" ]; then
    echo "No build directory supplied"
    exit 1
elif [ -z "$4" ]; then
    echo "No PrawnOS initramfs supplied"
    exit 1
elif [ -z "$5" ]; then
    echo "No PrawnOS target arch supplied"
    exit 1
elif [ -z "$6" ]; then
    echo "No PrawnOS kernel config supplied"
    exit 1
fi

KVER=$1
RESOURCES=$2
BUILD_DIR=$3
INITRAMFS=$4
TARGET=$5
KERNEL_CONFIG=$6

ARCH_ARMHF=armhf
ARCH_ARM64=arm64

cd $BUILD_DIR
make mrproper

CROSS_COMPILER=aarch64-linux-gnu-
KERNEL_ARCH=$ARCH_ARM64
IMAGE=zImage

#copy in the resources
cp "$KERNEL_CONFIG" .config


make CROSS_COMPILE=$CROSS_COMPILER ARCH=$KERNEL_ARCH oldconfig

# make -j $(($(nproc) +1))  CROSS_COMPILE=$CROSS_COMPILER ARCH=$KERNEL_ARCH $IMAGE

#TODO figure out dts from stock build system
# TODO looks like kernel.its is boot.its in the stock build, grab it
# cp $RESOURCES/kernel.its .
# make -j $(($(nproc) +1))  CROSS_COMPILE=$CROSS_COMPILER ARCH=$KERNEL_ARCH DTC_FLAGS="-@" dtbs

