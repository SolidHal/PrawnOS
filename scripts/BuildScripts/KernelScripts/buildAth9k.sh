#!/bin/bash

set -x
set -e

# build AR9271 firmware

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


if [ -z "$1" ]
then
    echo "No build directory supplied"
    exit 1
fi

BUILD_DIR=$1

unset TARGET
unset arm64
unset armhf
unset MAKEFLAGS
cd $BUILD_DIR
echo PRINT ENV
env
echo TARGET = "$TARGET" && make toolchain
echo TARGET = "$TARGET" && make -C target_firmware
