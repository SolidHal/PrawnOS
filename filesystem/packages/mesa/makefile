.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

#package specific vars
VERSION := $(shell cd src/; dpkg-parsechangelog --show-field Version)
PACKAGE_NAME := mesa_$(VERSION)_$(TARGET)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).phonydeb

PACKAGE_LOCAL_BUILD_DEPS :=

## Disable mesa for now since the upstream debian is currently newer, and we don't need anything even newer

default: skip
# default: $(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB)

install: install_skip
# install: install_real


.PHONY: skip
skip:
	echo Skipping mesa build since upstream debian is newer

$(PRAWNOS_LOCAL_APT_REPO)/$(PACKAGE_NAME_DEB): $(PRAWNOS_BUILD_DIRS) $(PACKAGE_NAME_DEB)
	cp libgbm1_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libgl1-mesa-dri_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libegl1-mesa_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libegl-mesa0_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libglapi-mesa_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libgl1-mesa-glx_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libgles2-mesa_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libglx-mesa0_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libosmesa6_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp libwayland-egl1-mesa_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp mesa-opencl-icd_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp mesa-va-drivers_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp mesa-vdpau-drivers_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)
	cp mesa-vulkan-drivers_*_$(TARGET).deb $(PRAWNOS_LOCAL_APT_REPO)

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

.PHONY: install_skip
install_skip:
	echo Skipping mesa install since upstream debian is newer

.PHONY: install_real
install_real:
	cp libgbm1_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libgl1-mesa-dri_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libegl1-mesa_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libegl-mesa0_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libglapi-mesa_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libgl1-mesa-glx_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libgles2-mesa_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libglx-mesa0_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libosmesa6_*_$(TARGET).deb $(INSTALL_TARGET)
	cp libwayland-egl1-mesa_*_$(TARGET).deb $(INSTALL_TARGET)
	cp mesa-opencl-icd_*_$(TARGET).deb $(INSTALL_TARGET)
	cp mesa-va-drivers_*_$(TARGET).deb $(INSTALL_TARGET)
	cp mesa-vdpau-drivers_*_$(TARGET).deb $(INSTALL_TARGET)
	cp mesa-vulkan-drivers_*_$(TARGET).deb $(INSTALL_TARGET)


.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD) $(PACKAGE_NAME).changes

