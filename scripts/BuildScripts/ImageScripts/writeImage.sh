#!/bin/bash

set -x
set -e

# ensure the target device is present, write the image, and force sync


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
    echo "No PrawnOS image supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No device supplied, supply like this: PDEV=/dev/sdX "
    exit 1
fi

IMAGE=$1
DEVICE=$2

if [ ! -b $DEVICE ]
then
    echo $DEVICE is not available, is it plugged in?
    exit 1
fi

dd if=$IMAGE of=$DEVICE bs=50M
sync

echo $IMAGE was written to $DEVICE successfully!
