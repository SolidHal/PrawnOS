#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/common.mk

VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := font-source-code-pro_$(VERSION)_all
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb

$(PACKAGE_NAME_DEB):
	@echo Building $@
	cd src/; debuild -us -uc

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

.PHONY: upload
upload:
	dput deb.prawnos.com *.changes

install:
ifndef INSTALL_TARGET
	$(error INSTALL_TARGET is not set)
endif
ifeq ("$(wildcard $(PACKAGE_NAME_DEB))","")
	$(error $(PACKAGE_NAME_DEB) must be built first)
endif
	cp $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)
