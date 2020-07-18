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

#Usage:
#run make image
#this will generate two images named PRAWNOS_IMAGE and PRAWNOS_IMAGE-BASE
#-BASE is only the filesystem with no kernel.


#if you make any changes to the kernel or kernel config with make kernel_config
#run kernel_inject


#:::::::::::::::::::::::::::::: cleaning ::::::::::::::::::::::::::::::
.PHONY: clean
clean:
	@echo "Enter one of:"
#TODO

.PHONY: clean_image
clean_image:
	rm -f $(PRAWNOS_IMAGE)

.PHONY: clean_basefs
clean_basefs:
	rm -f $(PRAWNOS_IMAGE_BASE)

.PHONY: clean_pbuilder
clean_pbuilder:
	rm -r build/prawnos-pbuilder-armhf-base.tgz

.PHONY: clean_all
clean_all: clean_kernel clean_initramfs clean_ath9k clean_image clean_basefs clean_pbuilder

#:::::::::::::::::::::::::::::: premake prep ::::::::::::::::::::::::::::::
.PHONY: build_dirs
build_dirs:
	mkdir -p $(PRAWNOS_BUILD_DIRS)

#:::::::::::::::::::::::::::::: kernel ::::::::::::::::::::::::::::::::::::
#included from kernel/makefile


#:::::::::::::::::::::::::::::: initramfs :::::::::::::::::::::::::::::::::
#included from initramfs/makefile

#:::::::::::::::::::::::::::::: filesystem ::::::::::::::::::::::::::::::::
#makes the base filesystem image without kernel. Only make a new one if the base image isnt present
#included from filesystem/makefile

#:::::::::::::::::::::::::::::: packages ::::::::::::::::::::::::::::::::
#included from filesystem/makefile

#:::::::::::::::::::::::::::::: image management ::::::::::::::::::::::::::

.PHONY: kernel_install
kernel_install: #Targets an already built .img and swaps the old kernel with the newly compiled kernel
	$(PRAWNOS_IMAGE_SCRIPTS_INSTALL_KERNEL) $(KVER) $(PRAWNOS_IMAGE)

.PHONY: kernel_update
kernel_update:
	$(MAKE) clean_image
	$(MAKE) initramfs
	$(MAKE) kernel TARGET=armhf
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_install

.PHONY: image
image:
	$(MAKE) clean_image
	$(MAKE) filesystem
	$(MAKE) initramfs
	$(MAKE) kernel TARGET=armhf
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_install


#:::::::::::::::::::::::::::::: dependency management ::::::::::::::::::::::::::

.PHONY: install_dependencies
install_dependencies:
	apt install --no-install-recommends --no-install-suggests \
    bc binfmt-support bison build-essential bzip2 ca-certificates cgpt cmake cpio debhelper \
    debootstrap device-tree-compiler devscripts file flex g++ gawk gcc gcc-aarch64-linux-gnu \
    gcc-arm-none-eabi git gpg gpg-agent kmod libc-dev libncurses-dev libssl-dev lzip make \
    parted patch pbuilder qemu-user-static sudo texinfo u-boot-tools udev vboot-kernel-utils wget

