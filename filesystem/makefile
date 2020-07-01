ifndef FILESYSTEM_MK
FILESYSTEM_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

FS_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/fs-log.txt

PRAWNOS_FILESYSTEM_PACKAGES := $(PRAWNOS_FILESYSTEM)/packages

PACKAGES_BUILT := $(PRAWNOS_FILESYSTEM_PACKAGES)/.packages_built

.PHONY: filesystem \
				pbuilder_create \
				pbuilder_update \
				filesystem_packages \
				filesystem_packages_clean \
				filesystem_packages_install

### Filesystem Image

filesystem: $(PRAWNOS_IMAGE_BASE)

### Packages

filesystem_packages: $(PRAWNOS_BUILD)

filesystem_packages_clean:
	$(MAKE) -C $(PRAWNOS_FILESYSTEM_PACKAGES) clean
	rm -f $(PRAWNOS_PACKAGES_BUILT)

filesystem_packages_install:
ifndef INSTALL_TARGET
	$(error INSTALL_TARGET is not set)
endif
	$(MAKE) -C $(PRAWNOS_FILESYSTEM_PACKAGES) INSTALL_TARGET=$(INSTALL_TARGET) install

### Pbuilder

pbuilder_create: $(PBUILDER_CHROOT)

#TODO: should only update if not updated for a day
pbuilder_update: $(PBUILDER_CHROOT)
	@echo UPDATING $(PBUILDER_CHROOT)
	pbuilder update --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)

### REAL TARGETS

$(PACKAGES_BUILT): $(PRAWNOS_BUILD) $(PBUILDER_CHROOT)
	$(MAKE) -C $(PRAWNOS_FILESYSTEM_PACKAGES) all
	touch $(PACKAGES_BUILT)

$(PBUILDER_CHROOT): $(PRAWNOS_BUILD)
	@echo BUILDING $(PBUILDER_CHROOT)
	pbuilder create --basetgz $(PBUILDER_CHROOT) --configfile $(PBUILDER_RC)

$(PRAWNOS_IMAGE_BASE): $(PRAWNOS_BUILD) $(PACKAGES_BUILT)
	rm -rf $(FS_BUILD_LOG)
	$(PRAWNOS_FILESYSTEM_SCRIPTS_BUILD) $(KVER) $(DEBIAN_SUITE) $(PRAWNOS_IMAGE_BASE) $(PRAWNOS_ROOT) $(PRAWNOS_SHARED_SCRIPTS) $(PRAWNOS_FILESYSTEM_RESOURCES) 2>&1 | tee $(FS_BUILD_LOG)


endif
