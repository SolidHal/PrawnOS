#!/bin/bash

set -x
set -e

# build perf for the PrawnOS linux kernel


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2020 Hal Emmerich <hal@halemmerich.com>

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
fi
if [ -z "$2" ]; then
    echo "No resources directory"
    exit 1
fi
if [ -z "$3" ]; then
    echo "No build directory supplied"
    exit 1
fi
if [ -z "$4" ]; then
    echo "No PrawnOS initramfs supplied"
    exit 1
fi
if [ -z "$5" ]; then
    echo "No PrawnOS target arch supplied"
    exit 1
fi


KVER=$1
RESOURCES=$2
BUILD_DIR=$3
INITRAMFS=$4
TARGET=$5

#assumes the kernel is already built, so we don't have to worry about janitorial work


cd $BUILD_DIR

sudo apt install libzstd-dev libelf-dev systemtap-sdt-dev libssl-dev libslang2-dev libperl-dev python-dev liblzma-dev libcap-dev libnuma-dev libbabeltrace-dev libbabeltrace-ctf-dev flex bison libiberty-dev binutils-dev libunwind-dev libdw-dev

ARCH_ARMHF=armhf
ARCH_ARM64=arm64

#this arch nonsense is obnoxious.
# armhf is just "arm" to the kernel
# arm64 is just arm64
if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    CROSS_COMPILER=arm-none-eabi-
    # kernel doesn't differentiate between arm and armhf
    KERNEL_ARCH=arm
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    CROSS_COMPILER=aarch64-linux-gnu-
    KERNEL_ARCH=$ARCH_ARM64
else
    echo "no valid target arch specified"
    exit 1
fi

cd tools/perf/
make -j $(($(nproc) +1))  CROSS_COMPILE=$CROSS_COMPILER ARCH=$KERNEL_ARCH

#TODO: for packaging, we can use make -C tools/ perf_install prefix=/usr/
