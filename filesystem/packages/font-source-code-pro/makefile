.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := font-source-code-pro_$(VERSION)_all
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb

default: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

$(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB): $(PACKAGE_NAME_DEB)
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)

$(PACKAGE_NAME_DEB):
	@echo Building $@
	cd src/; debuild -us -uc
	mkdir -p $(PRAWNOS_LOCAL_APT_REPO)
	cp $(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)

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

install:
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD)
