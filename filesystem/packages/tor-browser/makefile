.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := 14.0.3
PRAWNOS_VERSION := $(VERSION)-prawnos1
PACKAGE := tor-browser
PACKAGE_NAME := $(PACKAGE)_$(PRAWNOS_VERSION)_$(TARGET_ARCH)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb
PACKAGE_BUILD_DIR := $(PRAWNOS_BUILD)/$(PACKAGE)
PACKAGE_TARBALL_UNPACKED := $(PACKAGE_BUILD_DIR)/.unpacked
PACKAGE_LOCAL_BUILD_DEPS :=

#uses only the upstream kernel version for the orig tar
PACKAGE_NAME_ORIG := $(PACKAGE)_$(VERSION)
PACKAGE_NAME_ORIG_TAR = $(PACKAGE_BUILD_DIR)/$(PACKAGE_NAME_ORIG).orig.tar.gz
PACKAGE_NAME_ORIG_DIR = $(PACKAGE_BUILD_DIR)/$(PACKAGE_NAME_ORIG)-orig

# building the full browser takes *hours* and can only be done natively at this point,
# cross compilation support is not an option right now
# on an rk3588 board with 16GB ram it took nearly 20 hours :|
# so for those reasons we do not build the full tor-browser here
# instead we download the built tarball and package it
# see the repo https://gitlab.com/prawnos/tor-browser-build if you are interested in building it yourself
# the ci yml file has the (short) build commands https://gitlab.com/prawnos/tor-browser-build/-/blob/maint-14.0-aarch64/.gitlab-ci.yml?ref_type=heads

# if you would like your tor browser tarball to be built into your prawnos build, swap the link below with a link to your tarball
PACKAGE_TARBALL := https://gitlab.com/prawnos/tor-browser-build/-/package_files/163830794/download

default: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

$(PACKAGE_TARBALL_UNPACKED):
	rm -rf $(PACKAGE_BUILD_DIR)
	mkdir -p $(PACKAGE_BUILD_DIR)
	wget -O $(PACKAGE_BUILD_DIR)/tor-browser-linux-aarch64-14.0.3.tar.xz $(PACKAGE_TARBALL)
	tar -xJf $(PACKAGE_BUILD_DIR)/tor-browser-linux-aarch64-14.0.3.tar.xz -C $(PACKAGE_BUILD_DIR)
	touch $(PACKAGE_TARBALL_UNPACKED)

$(PACKAGE_NAME_ORIG_TAR): $(PACKAGE_TARBALL_UNPACKED)
	rm -rf $(PACKAGE_NAME_ORIG_DIR)
	rm -f $(PACKAGE_BUILD_DIR)/$(PACKAGE)_*-*.orig.tar.gz
	mkdir -p $(PACKAGE_NAME_ORIG_DIR)/tor-browser-bundle
	cp -a $(PACKAGE_BUILD_DIR)/tor-browser/* $(PACKAGE_NAME_ORIG_DIR)/tor-browser-bundle
	cp tor-browser.desktop $(PACKAGE_NAME_ORIG_DIR)/
	tar -czf $(PACKAGE_NAME_ORIG_TAR) -C $(PACKAGE_BUILD_DIR) $(notdir $(PACKAGE_NAME_ORIG_DIR))


$(PACKAGE_BUILD_DIR)/$(PACKAGE_NAME_DEB): $(PACKAGE_NAME_ORIG_TAR)
	rm -rf $(PACKAGE_BUILD_DIR)/src
	cp -a src $(PACKAGE_BUILD_DIR)
	cd $(PACKAGE_BUILD_DIR) && $(PRAWNOS_PACKAGE_SCRIPTS_PBUILD) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS)

$(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB): $(PACKAGE_BUILD_DIR)/$(PACKAGE_NAME_DEB) | $(PRAWNOS_LOCAL_APT_REPO)
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_BUILD_DIR)/$(PACKAGE_NAME_DEB) $(PRAWNOS_LOCAL_APT_REPO)


.PHONY: clean
clean:
	rm -rf $(PACKAGE_BUILD_DIR)

install: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD) $(PACKAGE_NAME).changes