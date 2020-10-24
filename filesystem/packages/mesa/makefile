.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := mesa_$(VERSION)_$(TARGET)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).phonydeb

PACKAGE_LOCAL_BUILD_DEPS :=

default: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

#libegl1-mesa-dev
#libgbm-dev
#libgbm1
#libgl1-mesa-dri
#libglapi-mesa
#mesa-common-dev
#mesa-vdpau-drivers
#mesa-va-drivers

$(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB): $(PRAWNOS_BUILD_DIRS) $(PACKAGE_NAME_DEB)
# TODO: install for each of the required mesa/panfrost packages
# $(PRAWNOS_PACKAGE_SCRIPTS_INSTALL)  $(PRAWNOS_LOCAL_APT_REPO)

$(PACKAGE_NAME_DEB):
	rm -f mesa_build.log
	$(PRAWNOS_PACKAGE_SCRIPTS_PBUILD) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS) 2>&1 | tee mesa_build.log

.PHONY: clean
clean:
	rm -rf $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes
	rm -rf *.build
	rm -rf *.diff.gz
	rm -rf *.debian.tar.xz
	rm -rf *.buildinfo

install:
#	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)
	cp *_$(TARGET).deb $(INSTALL_TARGET)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD) $(PACKAGE_NAME).changes

