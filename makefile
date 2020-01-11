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

KVER=5.2.21
ifeq ($(DEBIAN_SUITE),)
DEBIAN_SUITE=buster
endif
ifeq ($(PRAWNOS_SUITE),)
PRAWNOS_SUITE=Shiba
endif
OUTNAME=PrawnOS-$(PRAWNOS_SUITE)-c201.img
BASE=$(OUTNAME)-BASE


#Usage:
#run make image
#this will generate two images named OUTNAME and OUTNAME-BASE
#-BASE is only the filesystem with no kernel.


#if you make any changes to the kernel or kernel config with make kernel_config
#run kernel_inject



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

.PHONY: clean_all
clean_all:
	make clean_kernel
	make clean_ath
	make clean_img
	make clean_fs
	make clean_initramfs


.PHONY: kernel
kernel:
	scripts/buildKernel.sh $(KVER)

.PHONY: initramfs
initramfs:
	scripts/buildInitramFs.sh $(BASE)

#makes the base filesystem image, no kernel only if the base image isnt present
.PHONY: filesystem
filesystem:
	[ -f $(BASE) ] || scripts/buildFilesystem.sh $(KVER) $(DEBIAN_SUITE) $(BASE)

.PHONY: kernel_inject
kernel_inject: #Targets an already built .img and swaps the old kernel with the newly compiled kernel
	scripts/injectKernelIntoFS.sh $(KVER) $(OUTNAME)

.PHONY: injected_image
injected_image: #makes a copy of the base image with a new injected kernel
	make kernel
	cp $(BASE) $(OUTNAME)
	make kernel_inject

.PHONY: image
image:
	make clean_img
	make filesystem
	make initramfs
	make kernel
#Make a new copy of the filesystem image
	cp $(BASE) $(OUTNAME)
	make kernel_inject

.PHONY: live_image
live_image:
	echo "TODO"

.PHONY: kernel_config
kernel_config:
	scripts/crossmenuconfig.sh $(KVER)

.PHONY: patch_kernel
patch_kernel:
	scripts/patchKernel.sh
