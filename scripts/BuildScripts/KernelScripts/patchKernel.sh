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
if [ -z "$4" ]
then
    echo "No target arch supplied"
    exit 1
fi

KVER=$1
PATCHES=$2
BUILD_DIR=$3
TARGET=$4

ARCH_ARMHF=armhf
ARCH_ARM64=arm64

cd $BUILD_DIR
make mrproper


if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    #Apply the usb and mmc patches
    for i in "$PATCHES"/DTS/*.patch; do echo $i; patch -p1 < $i; done
    for i in "$PATCHES"/kernel/*.patch; do echo $i; patch -p1 < $i; done
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    #echo skip for now
    #for i in "$PATCHES"/kernel/*.patch; do echo $i; patch -p1 < $i; done
    for i in "$PATCHES"/drm/*.patch; do echo $i; patch -p1 < $i; done
    # for i in "$PATCHES"/cros-drm/*.patch; do echo $i; patch -p1 < $i; done
    # for i in "$PATCHES"/alarm/*.patch; do echo $i; patch -p1 < $i; done
else
    echo "no valid target arch specified"
    exit 1
fi
