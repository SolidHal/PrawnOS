#!/bin/bash

set -x
set -e

#Runs merge config with the proper enviroment vars for cross compiling arm 


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2024 Eva Emmerich <eva@evaemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.

PRAWNOS_ROOT=$(git rev-parse --show-toplevel)
source ${PRAWNOS_ROOT}/scripts/BuildScripts/BuildCommon.sh

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
    echo "No base config supplied"
    exit 1
fi
if [ -z "$5" ]
then
    echo "No config fragment supplied"
    exit 1
fi


RESOURCES=$1
BUILD_DIR=$2
TARGET=$3
CONFIG=$4
CONFIG_FRAGMENT=$5

cd $BUILD_DIR

if [ "$TARGET" == "$PRAWNOS_ARMHF" ]; then
    CROSS_COMPILER=arm-none-eabi-
    # kernel doesn't differentiate between arm and armhf
    ARCH=arm
elif [ "$TARGET" == "$PRAWNOS_ARM64" ]; then
    CROSS_COMPILER=aarch64-linux-gnu-
    ARCH=$ARCH_ARM64
elif [ "$TARGET" == "${PRAWNOS_ARM64_RK3588_SERVER}" ]; then
    CROSS_COMPILER=aarch64-linux-gnu-
    ARCH=$ARCH_ARM64
elif [ "$TARGET" == "${PRAWNOS_ARM64_RK3588}" ]; then
    CROSS_COMPILER=aarch64-linux-gnu-
    ARCH=$ARCH_ARM64
else
    echo "Cannot run cross make menuconfig: no valid target arch specified"
fi

cp $CONFIG .config
cp $CONFIG_FRAGMENT .config.fragment
ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILER ./scripts/kconfig/merge_config.sh .config .config.fragment
cp .config $CONFIG