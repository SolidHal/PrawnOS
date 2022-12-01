# This file is part of PrawnOS (https://www.prawnos.com)
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

.DEFAULT_GOAL := image
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk
include $(PRAWNOS_ROOT)/initramfs/makefile
include $(PRAWNOS_ROOT)/kernel/makefile
include $(PRAWNOS_ROOT)/filesystem/makefile
include $(PRAWNOS_ROOT)/bootloader/makefile

#Usage:
#run make image
#this will generate two images named PRAWNOS_IMAGE and PRAWNOS_IMAGE-BASE
#-BASE is only the filesystem with no kernel.


#if you make any changes to the kernel or kernel config with make kernel_config
#run kernel_inject



#:::::::::::::::::::::::::::::: cleaning ::::::::::::::::::::::::::::::
.PHONY: clean
clean:
	@echo "Enter one of the following:"
	@echo "clean_image      : removes the built PrawnOS-$(PRAWNOS_SUITE)-$(TARGET).img"
	@echo "clean_basefs     : removes the -BASE prawnos image which contains the base filesystem"
	@echo "clean_pbuilder   : removes the pbuilder chroot used to build the prawnos packages locally located in build/$(TARGET)/prawnos-pbuilder-$(TARGET)-base.tgz"
	@echo "clean_kernel     : removes the kernel build directory build/$(TARGET)/linux-<kver>"
	@echo "clean_bootloader : removes the kernel build directory build/$(TARGET)/bootloader"
	@echo "clean_ath9k      : removes the ath9k firmware build directory build/shared/open-ath9k-htc-firmware"
	@echo "clean_initramfs  : removes the built initramfs image located in build/$(TARGET)/PrawnOS-initramfs.cpio.gz"
	@echo "clean_most       : cleans kernel, initramfs, basefs, image, bootloader. these are the most common items required to clean for a full rebuild."
	@echo "clean_all        : runs all of the above clean commands, rarely needed. Most likely want clean_most"

.PHONY: clean_image
clean_image:
	rm -f $(PRAWNOS_IMAGE)

.PHONY: clean_basefs
clean_basefs:
	rm -f $(PRAWNOS_IMAGE_BASE)

.PHONY: clean_pbuilder
clean_pbuilder:
	rm -f $(PBUILDER_CHROOT)

.PHONY: clean_most
clean_most: clean_kernel clean_initramfs clean_image clean_basefs clean_bootloader
	@echo "cleaned kernel, initramfs, basefs, image"

.PHONY: clean_all
clean_all: clean_most clean_ath9k clean_pbuilder
	@echo "cleaned all"

#:::::::::::::::::::::::::::::: kernel ::::::::::::::::::::::::::::::::::::
#included from kernel/makefile

#:::::::::::::::::::::::::::::: initramfs :::::::::::::::::::::::::::::::::
#included from initramfs/makefile

#:::::::::::::::::::::::::::::: filesystem ::::::::::::::::::::::::::::::::
#makes the base filesystem image without kernel. Only make a new one if the base image isnt present
#included from filesystem/makefile

#:::::::::::::::::::::::::::::: packages ::::::::::::::::::::::::::::::::
#included from filesystem/makefile

#:::::::::::::::::::::::::::::: bootloader ::::::::::::::::::::::::::::::::
#included from bootloader/makefile

#:::::::::::::::::::::::::::::: image management ::::::::::::::::::::::::::

.PHONY: kernel_install
kernel_install: #Targets the PrawnOS image and installs a kernel
	$(MAKE) kernel_image_package_install

.PHONY: kernel_update
kernel_update:
	$(MAKE) clean_image
	$(MAKE) clean_kernel
	$(MAKE) initramfs
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_image_package_install


.PHONY: bootloader_install
bootloader_install: #Targets the PrawnOS image and installs a bootloader
ifeq ($(TARGET), $(PRAWNOS_ARM64_RK3588_SERVER))
	$(MAKE) bootloader_image_package_install
else
	echo "No bootloader to install for target ${TARGET}"
endif

.PHONY: bootloader_update
bootloader_update:
ifeq ($(TARGET), $(PRAWNOS_ARM64_RK3588_SERVER))
	$(MAKE) clean_image
	$(MAKE) clean_bootloader
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_image_package_install
	$(MAKE) bootloader_image_package_install
else
	echo "No bootloader to update for target ${TARGET}"
endif

.PHONY: image
image:
	$(MAKE) clean_image
	$(MAKE) filesystem
	$(MAKE) initramfs
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_image_package_install
ifeq ($(TARGET), $(PRAWNOS_ARM64_RK3588_SERVER))
	$(MAKE) bootloader_image_package_install
endif

# $PDEV should be passed like PDEV=/dev/sdb
.PHONY: write_image
write_image: $(PRAWNOS_IMAGE)
	$(PRAWNOS_IMAGE_SCRIPTS_WRITE_IMAGE) $(PRAWNOS_IMAGE) $(PDEV)

.PHONE: release
release: $(PRAWNOS_IMAGE_GIT_GZ)

$(PRAWNOS_IMAGE):
	$(MAKE) image

$(PRAWNOS_IMAGE_GIT_GZ): $(PRAWNOS_IMAGE)
	cp $(PRAWNOS_IMAGE) $(PRAWNOS_IMAGE_GIT)
	gzip -c $(PRAWNOS_IMAGE_GIT) > $(PRAWNOS_IMAGE_GIT_GZ)

#:::::::::::::::::::::::::::::: dependency management ::::::::::::::::::::::::::

.PHONY: install_dependencies
install_dependencies:
	apt install --no-install-recommends --no-install-suggests $(AUTO_YES) \
    bc binfmt-support bison build-essential bzip2 ca-certificates cgpt cmake cpio debhelper \
    debootstrap device-tree-compiler devscripts file flex g++ gawk gcc gcc-aarch64-linux-gnu \
    gcc-arm-none-eabi git gpg gpg-agent kmod libc-dev libncurses-dev libssl-dev lzip make \
    parted patch pbuilder qemu-user-static quilt rsync sudo texinfo u-boot-tools udev vboot-kernel-utils wget

.PHONY: install_dependencies_yes
install_dependencies_yes:
	$(MAKE) AUTO_YES="-y" install_dependencies
