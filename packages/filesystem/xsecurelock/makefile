SHELL := /bin/bash
PRAWNOS_ROOT := $(shell cd ../../../; pwd)
PBUILDER_CHROOT=$(PRAWNOS_ROOT)/build/prawnos-pbuilder-armhf-base.tgz
PBUILDER_RC=$(PRAWNOS_ROOT)/resources/BuildResources/pbuilder/prawnos-pbuilder.rc

all: xsecurelock-deb

.PHONY: xsecurelock-deb
xsecurelock-deb:
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


