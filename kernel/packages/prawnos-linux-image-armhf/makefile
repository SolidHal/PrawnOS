.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_PREFIX := prawnos-linux-image-armhf
PACKAGE_ARCH := armhf
#uses the full debian version for the package name
PACKAGE_NAME :=  $(PACKAGE_PREFIX)_$(VERSION)_$(PACKAGE_ARCH)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb
#uses only the upstream kernel version for the orig tar
PACKAGE_NAME_ORIG_TAR := $(PACKAGE_PREFIX)_$(KVER).orig.tar.gz

ORIG := $(PRAWNOS_KERNEL_PACKAGE_IMAGE)/orig

default: $(PACKAGE_NAME_DEB)

$(PACKAGE_NAME_DEB): $(PACKAGE_NAME_ORIG_TAR)
	@echo Building $@
# keep the /debian files up to date with the current kernel version
	$(PRAWNOS_KERNEL_SCRIPTS_UPDATE_DEB_FILES) $(PRAWNOS_KERNEL_PACKAGE_IMAGE)/src $(DEBKVER)
	$(PRAWNOS_PACKAGE_SCRIPTS_PBUILD) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS)
	mkdir -p $(PRAWNOS_LOCAL_APT_REPO)
	cp $(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)

$(PACKAGE_NAME_ORIG_TAR):
	make -f $(PRAWNOS_KERNEL)/makefile kernel
	cp $(PRAWNOS_KERNEL_BUILT) $(ORIG)/$(PACKAGE_NAME)
	tar -czf $(PACKAGE_NAME_ORIG_TAR) -C $(ORIG)/ .

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
	rm -rf src/debian/$(PACKAGE_PREFIX)*
	rm -f src/debian/files
	rm -rf src/debian/.debhelper
# kernel package specific
	rm -f orig/$(PACKAGE_NAME)
	rm -f $(PACKAGE_NAME_ORIG_TAR)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD)
