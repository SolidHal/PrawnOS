.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME :=  prawnos-linux-image-armhf_$(VERSION)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb
PACKAGE_NAME_ORIG_TAR := prawnos-linux-image-armhf_$(KVER).orig.tar.gz

ORIG := $(PRAWNOS_KERNEL_PACKAGE_IMAGE)/orig

default: $(PACKAGE_NAME_DEB)

$(PACKAGE_NAME_DEB): $(PACKAGE_NAME_ORIG_TAR)
	@echo Building $@
# keep the /debian files up to date with the current kernel version
	$(PRAWNOS_KERNEL_SCRIPTS_UPDATE_DEB_FILES) $(PRAWNOS_KERNEL_PACKAGE_IMAGE)/src $(DEBKVER)
	cd src/; debuild -us -uc
	mkdir -p $(PRAWNOS_LOCAL_APT_REPO)
	cp $(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)

$(PACKAGE_NAME_ORIG_TAR):
	make -f $(PRAWNOS_KERNEL)/makefile kernel
	cp $(PRAWNOS_KERNEL_BUILT) $(ORIG)/$(PACKAGE_NAME)
	tar -czf $(PACKAGE_NAME_ORIG_TAR) $(ORIG)/

.PHONY: clean
clean:
	rm -rf $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes
	rm -rf *.dsc
	rm -rf *.build
	rm -rf *.diff.gz
	rm -rf *.debian.tar.xz
	rm -rf *.buildinfo
	rm -f src/debian/debhelper-build-stamp
	rm -rf src/debian/prawnos-linux-image-armhf*
	rm -f src/debian/files
# kernel package specific
	rm -f orig/prawnos-linux-image-armhf_$(VERSION)
	rm -f prawnos-linux-image-armhf_$(KVER).orig.tar.gz

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD)
