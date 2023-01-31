
# build uboot for veyron speedy

sudo apt install u-boot-tools
sudo apt install python3-distutils
sudo apt install swig python3-dev

# checkout the uboot repo

# config

make menuconfig CROSS_COMPILE=arm-linux-gnueabihf- chromebook_speedy_defconfig
enable: boot media -> SD/EMMC and SPI Flash (not sure if necessary)
can also enable uart over usb under Arm Architecture

# build

make CROSS_COMPILE=arm-linux-gnueabihf- chromebook_speedy_defconfig


# Stage 2 bootloaders
## use grub as a (stage2) bootloader with uboot?
https://forum.odroid.com/viewtopic.php?t=26894
