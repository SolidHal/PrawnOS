
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/common.mk

VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
EMPTY := ""

font-source-code-pro_$(VERSION)_all.deb:
	@echo Building $@
	cd src/; debuild -us -uc

.PHONY: clean
clean:
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes

.PHONY: upload
upload:
	dput deb.prawnos.com *.changes

install:
ifndef INSTALL_TARGET
	$(error INSTALL_TARGET is not set)
endif
	cp font-source-code-pro_$(VERSION)_all.deb $(INSTALL_TARGET)
