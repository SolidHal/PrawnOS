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

KVER=5.4.29
ifeq ($(DEBIAN_SUITE),)
DEBIAN_SUITE=buster
endif
ifeq ($(PRAWNOS_SUITE),)
PRAWNOS_SUITE=Shiba
endif
OUTNAME=PrawnOS-$(PRAWNOS_SUITE)-c201.img
BASE=$(OUTNAME)-BASE


PRAWNOS_ROOT := $(shell pwd)
PBUILDER_CHROOT=$(PRAWNOS_ROOT)/build/prawnos-pbuilder-armhf-base.tgz
PBUILDER_RC=$(PRAWNOS_ROOT)/resources/BuildResources/pbuilder/prawnos-pbuilder.rc

# Otherwise errors are ignored when output is piped to tee:
SHELL=/bin/bash -o pipefail

#Usage:
#run make image
#this will generate two images named OUTNAME and OUTNAME-BASE
#-BASE is only the filesystem with no kernel.


#if you make any changes to the kernel or kernel config with make kernel_config
#run kernel_inject


#:::::::::::::::::::::::::::::: cleaning ::::::::::::::::::::::::::::::
.PHONY: clean
clean:
	@echo "Enter one of:"
	@echo "	clean_kernel - which deletes the untar'd kernel folder from build"
	@echo "	clean_ath - which deletes the untar'd ath9k driver folder from build"
	@echo "	clean_img - which deletes the built PrawnOS image, this is ran when make image is ran"
	@echo " clean_basefs - which deletes the built PrawnOS base image"
	@echo " clean_initramfs - which deletes the built PrawnOS initramfs image that gets injected into the kernel"
	@echo "	clean_all - which does all of the above"
	@echo "	in most cases none of these need to be used manually as most cleanup steps are handled automatically"

.PHONY: clean_kernel
clean_kernel:
	rm -rf build/linux-$(KVER)

.PHONY: clean_ath
clean_ath:
	rm -rf build/open-ath9k-htc-firmware

.PHONY: clean_img
clean_img:
	rm -f $(OUTNAME)

.PHONY: clean_basefs
clean_basefs:
	rm -r $(BASE)

.PHONY: clean_initramfs
clean_initramfs:
	rm -r build/PrawnOS-initramfs.cpio.gz

.PHONY: clean_pbuilder
clean_pbuilder:
	rm -r build/prawnos-pbuilder-armhf-base.tgz

.PHONY: clean_all
clean_all:
	$(MAKE) clean_kernel
	$(MAKE) clean_ath
	$(MAKE) clean_img
	$(MAKE) clean_basefs
	$(MAKE) clean_initramfs
	$(MAKE) clean_pbuilder

#:::::::::::::::::::::::::::::: premake prep ::::::::::::::::::::::::::::::
.PHONY: build_dirs
build_dirs:
	mkdir -p build/logs/

#:::::::::::::::::::::::::::::: kernel ::::::::::::::::::::::::::::::::::::
.PHONY: kernel
kernel:
	$(MAKE) build_dirs
	rm -rf build/logs/kernel-log.txt
	./scripts/buildKernel.sh $(KVER) 2>&1 | tee build/logs/kernel-log.txt

.PHONY: kernel_config
kernel_config:
	scripts/crossmenuconfig.sh $(KVER)

.PHONY: patch_kernel
patch_kernel:
	scripts/patchKernel.sh

#:::::::::::::::::::::::::::::: initramfs :::::::::::::::::::::::::::::::::
.PHONY: initramfs
initramfs:
	$(MAKE) build_dirs
	rm -rf build/logs/initramfs-log.txt
	./scripts/buildInitramFs.sh $(BASE) 2>&1 | tee build/logs/initramfs-log.txt

#:::::::::::::::::::::::::::::: filesystem ::::::::::::::::::::::::::::::::
#makes the base filesystem image without kernel. Only make a new one if the base image isnt present
.PHONY: filesystem
filesystem:
	$(MAKE) build_dirs
	rm -rf build/logs/fs-log.txt
	$(MAKE) pbuilder_create
	[ -f $(BASE) ] || ./scripts/buildFilesystem.sh $(KVER) $(DEBIAN_SUITE) $(BASE) 2>&1 | tee build/logs/fs-log.txt


#:::::::::::::::::::::::::::::: image management ::::::::::::::::::::::::::

.PHONY: kernel_inject
kernel_inject: #Targets an already built .img and swaps the old kernel with the newly compiled kernel
	scripts/injectKernelIntoFS.sh $(KVER) $(OUTNAME)

.PHONY: kernel_update
kernel_update:
	$(MAKE) clean_img
	$(MAKE) initramfs
	$(MAKE) kernel
	cp $(BASE) $(OUTNAME)
	$(MAKE) kernel_inject

.PHONY: image
image:
	$(MAKE) clean_img
	$(MAKE) filesystem
	$(MAKE) initramfs
	$(MAKE) kernel
	cp $(BASE) $(OUTNAME)
	$(MAKE) kernel_inject


#:::::::::::::::::::::::::::::: pbuilder management :::::::::::::::::::::::
.PHONY: pbuilder_create
pbuilder_create:
	$(MAKE) $(PBUILDER_CHROOT)

$(PBUILDER_CHROOT): $(PBUILDER_RC)
	pbuilder create --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)

#TODO: should only update if not updated for a day
.PHONY: pbuilder_update
pbuilder_update:
	pbuilder update --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)
