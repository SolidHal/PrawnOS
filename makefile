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
clean_img:
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
build_dirs: $(PRAWNOS_BUILD)


#:::::::::::::::::::::::::::::: kernel ::::::::::::::::::::::::::::::::::::
#included from kernel/makefile


#:::::::::::::::::::::::::::::: initramfs :::::::::::::::::::::::::::::::::
#included from initramfs/makefile

#:::::::::::::::::::::::::::::: filesystem ::::::::::::::::::::::::::::::::
#makes the base filesystem image without kernel. Only make a new one if the base image isnt present
.PHONY: filesystem
filesystem:
	$(MAKE) build_dirs
	rm -rf build/logs/fs-log.txt
	$(MAKE) pbuilder_create
	$(MAKE) filesystem_packages
	[ -f $(PRAWNOS_IMAGE_BASE) ] || $(PRAWNOS_FILESYSTEM_SCRIPTS_BUILD) $(KVER) $(DEBIAN_SUITE) $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_ROOT) $(PRAWNOS_SHARED_SCRIPTS) 2>&1 | tee build/logs/fs-log.txt

#:::::::::::::::::::::::::::::: packages ::::::::::::::::::::::::::::::::
.PHONY: filesystem_packages
filesystem_packages:
	$(MAKE) filesystem_packages -C packages

.PHONY: filesystem_packages_install
filesystem_packages_install:
ifndef INSTALL_TARGET
	$(error INSTALL_TARGET is not set)
endif
	$(MAKE) filesystem_packages_install INSTALL_TARGET=$(INSTALL_TARGET) -C filesystem

#:::::::::::::::::::::::::::::: image management ::::::::::::::::::::::::::

.PHONY: kernel_install
kernel_inject: #Targets an already built .img and swaps the old kernel with the newly compiled kernel
	$(PRAWNOS_IMAGE_SCRIPTS_INSTALL_KERNEL) $(KVER) $(PRAWNOS_IMAGE)

.PHONY: kernel_update
kernel_update:
	$(MAKE) clean_img
	$(MAKE) initramfs
	$(MAKE) kernel
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_install

.PHONY: image
image:
	$(MAKE) clean_img
	$(MAKE) filesystem
	$(MAKE) initramfs
	$(MAKE) kernel
	cp $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_IMAGE)
	$(MAKE) kernel_install

#:::::::::::::::::::::::::::::: pbuilder management :::::::::::::::::::::::
.PHONY: pbuilder_create
pbuilder_create:
	$(MAKE) $(PBUILDER_CHROOT)

$(PBUILDER_CHROOT):
	pbuilder create --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)

#TODO: should only update if not updated for a day
.PHONY: pbuilder_update
pbuilder_update:
	pbuilder update --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)
