#!/bin/bash

set -x
set -e

#Runs Make menuconfig with the proper enviroment vars for cross compiling arm 
#Grabs the file named config in resources/BuildResources directory, and updates it


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
    echo "No resources directory"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No build directory supplied"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No TARGET supplied"
    exit 1
fi
if [ -z "$4" ]
then
    echo "No kernel config supplied"
    exit 1
fi

RESOURCES=$1
BUILD_DIR=$2
TARGET=$3
CONFIG=$4

ARCH_ARMHF=armhf
ARCH_ARM64=arm64

cd $BUILD_DIR

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

cp $CONFIG .config
make menuconfig ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILER .config
cp .config $CONFIG
