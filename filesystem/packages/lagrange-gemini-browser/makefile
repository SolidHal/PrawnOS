.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := lagrange-gemini-browser_$(VERSION)_$(TARGET)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb

UPSTREAM_VERSION := 
PACKAGE_ORIG_SRC := lagrange-gemini-browser_$(VERSION)

PACKAGE_LOCAL_BUILD_DEPS :=


default: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

$(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB): $(PRAWNOS_BUILD_DIRS) $(PACKAGE_NAME_DEB)
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)


$(PACKAGE_NAME_DEB):
	$(PRAWNOS_PACKAGE_SCRIPTS_PBUILD) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS)

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
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD) $(PACKAGE_NAME).changes


## get src
# wget https://git.skyjake.fi/skyjake/lagrange/releases/download/v0.11.0/lagrange-0.11.0.tar.gz
# mv lagrance-0*.tar.gz lagrange-gemini-browser_0.11.0.orig.tar.gz
