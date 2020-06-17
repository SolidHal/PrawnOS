#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/common.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := flashmap_$(VERSION)_armhf
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb

PACKAGE_LOCAL_BUILD_DEPS :=

$(PACKAGE_NAME_DEB):
	$(PRAWNOS_PACKAGE_SCRIPTS_PBUILD_PACKAGE) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS)

.PHONY: clean
clean:
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes
	rm -rf *.dsc
	rm -rf *.build
	rm -rf *.diff.gz
	rm -rf *.debian.tar.xz
	rm -rf *.buildinfo

install:
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL_PACKAGE) $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)

.PHONY: upload
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD_PACKAGE)
