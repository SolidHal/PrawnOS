#!/bin/bash

set -x
set -e

# build Linux-libre, with ath9k_htc firmware and initramfs built in


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2022 Hal Emmerich <hal@halemmerich.com>

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
    echo "No uboot version supplied"
    exit 1
elif [ -z "$2" ]; then
    echo "No resources directory"
    exit 1
elif [ -z "$3" ]; then
    echo "No build directory supplied"
    exit 1
elif [ -z "$4" ]; then
    echo "No PrawnOS kernel config supplied"
    exit 1
fi

UBOOTVER=$1
RESOURCES=$2
BUILD_DIR=$3
UBOOT_CONFIG=$4

# TODO copy in config, build uboot
# TODO then need to setup a package, like we have for the kernel, for uboot as well
