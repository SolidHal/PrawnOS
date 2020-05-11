#!/bin/bash

set -x
set -e

#Runs Make menuconfig with the proper enviroment vars for cross compiling arm 
#Grabs the file named config in resources/BuildResources directory, and updates it


# This file is part of PrawnOS (http://www.prawnos.com)
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
    echo "No kernel version supplied"
    exit 1
fi
KVER=$1


TEST_PATCHES=false
ROOT_DIR=`pwd`
RESOURCES=$ROOT_DIR/resources/BuildResources

[ ! -d build ] && mkdir build
cd build
# build Linux-libre, with ath9k_htc
[ ! -f linux-libre-$KVER-gnu.tar.lz ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz
[ ! -d linux-$KVER ] && tar --lzip -xvf linux-libre-$KVER-gnu.tar.lz && FRESH=true
cd linux-$KVER
make clean
make mrproper
#Apply the usb and mmc patches if unapplied
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/kernel/5.x-dwc2/*.patch; do echo $i; patch -p1 < $i; done
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/DTS/*.patch; do echo $i; patch -p1 < $i; done
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/kernel/*.patch; do echo $i; patch -p1 < $i; done

cp $RESOURCES/config .config
make menuconfig ARCH=arm CROSS_COMPILE=arm-none-eabi- .config
cp .config $RESOURCES/config
