#!/bin/bash

set -x
set -e

if [ -z "$1" ]
then
    echo "No kernel version supplied"
    exit 1
fi
KVER=$1

ROOT_DIR=`pwd`
RESOURCES=$ROOT_DIR/resources/BuildResources


[ ! -d build ] && mkdir build
cd build
# build Linux-libre, with ath9k_htc
cd linux-$KVER
make clean
make mrproper
#Apply the usb and mmc patches if unapplie
for i in $RESOURCES/patches-tested/DTS/*.patch; do patch -p1 < $i; done
for i in $RESOURCES/patches-tested/kernel/*.patch; do patch -p1 < $i; done

cd $ROOT_DIR
