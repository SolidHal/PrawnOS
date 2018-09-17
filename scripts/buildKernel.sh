#!/bin/sh -xe

#Build kenerl, wifi firmware


TEST_PATCHES=false

ROOT_DIR=`pwd`
RESOURCES=$ROOT_DIR/resources/BuildResources


[ ! -d build ] && mkdir build
cd build

# build the Chrome OS kernel, with ath9k_htc and without many useless drivers
[ ! -d chromeos-3.14 ] && git clone --depth 1 -b chromeos-3.14 https://chromium.googlesource.com/chromiumos/third_party/kernel chromeos-3.14
[ ! -f deblob-3.14 ] && wget http://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-3.14.N/deblob-3.14
[ ! -f deblob-check ] && wget http://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-3.14.N/deblob-check
cd chromeos-3.14
# deblob as much as possible - the diff against vanilla 3.14.x is big but
# blob-free ath9k_htc should be only driver that requests firmware
AWK=gawk sh ../deblob-3.14 --force
export WIFIVERSION=-3.8
./chromeos/scripts/prepareconfig chromiumos-rockchip
cp $RESOURCES/config .config

# reset the minor version number, so out-of-tree drivers continue to work after
# a kernel upgrade **TODO - is this needed?
# sed s/'SUBLEVEL = .*'/'SUBLEVEL = 0'/ -i Makefile
cp $RESOURCES/config .config
make -j `grep ^processor /proc/cpuinfo  | wc -l`  CROSS_COMPILE=arm-none-eabi- ARCH=arm zImage modules dtbs
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


# build AR9271 firmware
[ ! -d open-ath9k-htc-firmware ] && git clone --depth 1 https://github.com/qca/open-ath9k-htc-firmware.git
cd open-ath9k-htc-firmware
make toolchain
make -C target_firmware
cd ..
cd $ROOT_DIR

