#!/bin/sh -xe

#Runs Make menuconfig with the proper enviroment vars for cross compiling arm 
#Grabs the file named config in resources/BuildResources directory, and updates it

KVER=4.17.2

ROOT_DIR=`pwd`
RESOURCES=$ROOT_DIR/resources/BuildResources
[ ! -d build ] && mkdir build
cd build
[ ! -f linux-libre-$KVER-gnu.tar.lz ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz
[ ! -d linux-$KVER ] && tar --lzip -xvf linux-libre-$KVER-gnu.tar.lz
cd linux-$KVER
cp $RESOURCES/config .config
make menuconfig ARCH=arm CROSS_COMPILE=arm-none-eabi- .config
cp .config $RESOURCES/config
