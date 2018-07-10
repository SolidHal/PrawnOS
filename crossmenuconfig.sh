#!/bin/sh -xe

#Runs Make menuconfig with the proper enviroment vars for cross compiling arm 
#Grabs the file named config in the same directory as this script, and updates it

KVER=4.17.5

[ ! -f linux-libre-$KVER-gnu.tar.lz ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz
[ ! -d linux-$KVER ] && tar --lzip -xvf linux-libre-$KVER-gnu.tar.lz
cd linux-$KVER
cp ../config .config
make menuconfig ARCH=arm CROSS_COMPILE=arm-none-eabi- .config
cp .config ../config
