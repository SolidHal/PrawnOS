#!/bin/sh -xe

#Build kenerl, wifi firmware


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
if [ ! -f PrawnOS-initramfs.cpio.gz ]
then
    echo "No initramfs image, run 'make initramfs' first"
    cd $ROOT_DIR
    exit 1
fi
# build AR9271 firmware
[ ! -d open-ath9k-htc-firmware ] && git clone --depth 1 https://github.com/qca/open-ath9k-htc-firmware.git
cd open-ath9k-htc-firmware
make toolchain
make -C target_firmware
cd ..

# build Linux-libre, with ath9k_htc
[ ! -f linux-libre-$KVER-gnu.tar.lz ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz
[ ! -f linux-libre-$KVER-gnu.tar.lz.sign ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz.sign

#verify the signature
gpg --import $RESOURCES/linux-libre-signing-key.gpg
gpg --verify linux-libre-$KVER-gnu.tar.lz.sign linux-libre-$KVER-gnu.tar.lz

[ ! -d linux-$KVER ] && tar --lzip -xvf linux-libre-$KVER-gnu.tar.lz && FRESH=true
cd linux-$KVER
make clean
make mrproper
#Apply the usb and mmc patches if unapplied
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/kernel/5.x-dwc2/*.patch; do echo $i; patch -p1 < $i; done
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/DTS/*.patch; do echo $i; patch -p1 < $i; done
[ "$FRESH" = true ] && for i in $RESOURCES/patches-tested/kernel/*.patch; do echo $i; patch -p1 < $i; done

#copy in the initramfs and kernel config
cp $ROOT_DIR/build/PrawnOS-initramfs.cpio.gz .
cp $RESOURCES/config .config
make -j $((`nproc` +1))  CROSS_COMPILE=arm-none-eabi- ARCH=arm zImage modules dtbs
[ ! -h kernel.its ] && ln -s $RESOURCES/kernel.its .
mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack vmlinux.kpart \
              --version 1 \
              --vmlinuz vmlinux.uimg \
              --arch arm \
              --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
              --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
              --config $RESOURCES/cmdline \
              --bootloader bootloader.bin
cd ..
cd $ROOT_DIR
