#!/bin/bash

set -x
set -e

# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2023 Eva Emmerich <hal@halemmerich.com>

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
    echo "No kernel version supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No patches directory"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No build directory supplied"
    exit 1
fi
if [ -z "$4" ]
then
    echo "No target arch supplied"
    exit 1
fi
if [ -z "$5" ]
then
    echo "No kernel type supplied"
    exit 1
fi

KVER=$1
PATCHES=$2
BUILD_DIR=$3
TARGET=$4
TYPE=$5

cd $BUILD_DIR
make mrproper


if [ "$TARGET" == "$PRAWNOS_ARMHF" ]; then
    #Apply the usb and mmc patches
    for i in "$PATCHES"/DTS/*.patch; do echo $i; patch -p1 < $i; done
    for i in "$PATCHES"/kernel/*.patch; do echo $i; patch -p1 < $i; done
elif [ "$TARGET" == "$PRAWNOS_ARM64" ]; then
    # for i in "$PATCHES"/drm/*.patch; do echo $i; patch -p1 < $i; done
    if [ "$TYPEl" != "$PRAWNOS_BLOBBY_KERNEL" ]; then
        # the sound patch does not apply to blobby kernel since it has the firmware
        for i in "$PATCHES"/sound/0001-rk3399-gru-sound-dont-try-to-probe-cdn-dp.patch; do echo $i; patch -p1 < $i; done
    fi
elif [ "$TARGET" == "${PRAWNOS_ARM64_RK3588_SERVER}" ]; then
    echo skip for now, we are just using a git repo for the source
elif [ "$TARGET" == "${PRAWNOS_ARM64_RK3588}" ]; then
    echo skip for now, we are just using a git repo for the source
else
    echo "Cannot patch kernel: no valid target arch specified"
    exit 1
fi
