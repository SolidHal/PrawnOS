#!/bin/sh -xe

#Build kenerl, wifi firmware


KVER=4.17.2

# build Linux-libre, with ath9k_htc, dwc2 from Chrome OS and without many useless drivers
[ ! -f linux-libre-$KVER-gnu.tar.lz ] && wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$KVER-gnu/linux-libre-$KVER-gnu.tar.lz
[ ! -d linux-$KVER ] && tar --lzip -xvf linux-libre-$KVER-gnu.tar.lz
cd linux-$KVER
make clean
make mrproper
# rm -rf drivers/usb/dwc2
# ln -s ../../../chromeos-3.14/drivers/usb/dwc2 drivers/usb/
# patch -p 1 < ../chromeos-dwc2-glue.patch
# reset the minor version number, so out-of-tree drivers continue to work after
# a kernel upgrade
sed s/'SUBLEVEL = .*'/'SUBLEVEL = 0'/ -i Makefile
cp ../config .config
make -j `grep ^processor /proc/cpuinfo  | wc -l` olddefconfig CROSS_COMPILE=arm-none-eabi- ARCH=arm zImage modules dtbs
[ ! -h kernel.its ] && ln -s ../kernel.its .
mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack vmlinux.kpart \
              --version 1 \
              --vmlinuz vmlinux.uimg \
              --arch arm \
              --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
              --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
              --config ../cmdline \
              --bootloader bootloader.bin
cd ..

#TODO: Should be able to just include this in /lib/firmware of the target os, and it should be loaded. 
# or Should be able to include firmware in kernel through kernel config, external firmware.
# Then the firmware doesn't have to be included in the target fs /lib/firmware

# Either of these should fix the error about the kernel not being able to load the firmware,
# as it is looking for the propriatary blob and stumbles upon this one in /lib/firmware right now

# build AR9271 firmware
[ ! -d open-ath9k-htc-firmware ] && git clone --depth 1 https://github.com/qca/open-ath9k-htc-firmware.git
cd open-ath9k-htc-firmware
make toolchain
make -C target_firmware
cd ..
