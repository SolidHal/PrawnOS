#!/bin/bash

set -x
set -e

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
KVER=$1
PATCHES=$2
BUILD_DIR=$3

cd $BUILD_DIR
make mrproper
#Apply the usb and mmc patches
for i in "$PATCHES"/DTS/*.patch; do echo $i; patch -p1 < $i; done
for i in "$PATCHES"/kernel/*.patch; do echo $i; patch -p1 < $i; done
