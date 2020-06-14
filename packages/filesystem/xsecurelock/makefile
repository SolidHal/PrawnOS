#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/common.mk


VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)

xsecurelock_$(VERSION)_armhf.deb:
	@echo Building $@
	cd src/; pdebuild --configfile $(PBUILDER_RC) \
                    --buildresult .. \
                    -- \
                    --basetgz $(PBUILDER_CHROOT) \

.PHONY: clean
clean:
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes
	rm -rf *.dsc
	rm -rf *.build
	rm -rf *.debian.tar.xz
	rm -rf *.buildinfo

.PHONY: upload
upload:
	dput deb.prawnos.com *.changes

install:
ifndef INSTALL_TARGET
	$(error INSTALL_TARGET is not set)
endif
	cp xsecurelock_$(VERSION)_armhf.deb $(INSTALL_TARGET)

