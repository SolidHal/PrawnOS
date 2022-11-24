ifndef BOOTLOADER_MK
BOOTLOADER_MK := 1

ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif

include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk
include $(PRAWNOS_ROOT)/initramfs/makefile

### TARGETED VARS ###
BOOTLOADER_PATCHED := $(PRAWNOS_BOOTLOADER_BUILD)/.bootloader_patched
BOOTLOADER_EXTRACTED := $(PRAWNOS_BOOTLOADER_BUILD)/.bootloader_extracted

BOOTLOADER_PATCHES := $(PRAWNOS_BOOTLOADER)/patches/$(TARGET)

BOOTLOADER_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/bootloader-log-$(TARGET).txt

BOOTLOADER_CONFIG := $(PRAWNOS_BOOTLOADER_RESOURCES)/config

BOOTLOADER_URL := https://github.com/u-boot/u-boot.git

### PHONY RULES
.PHONY: bootloader
bootloader: $(PRAWNOS_BOOTLOADER_BUILT)


.PHONY: patch_bootloader
patch_bootloader: $(BOOTLOADER_PATCHED)


.PHONY: bootloader_image_package
bootloader_image_package: $(PRAWNOS_BOOTLOADER_BUILT)
ifeq ($(TARGET), $(PRAWNOS_ARM64_RK3588_SERVER))
	$(MAKE) -C $(PRAWNOS_BOOTLOADER_UBOOT_PACKAGE_IMAGE)
else
  echo "No bootloader package to build for target ${TARGET}"
endif

.PHONY: bootloader_image_package_install
bootloader_image_package_install: bootloader_image_package
ifeq ($(TARGET), $(PRAWNOS_ARM64_RK3588_SERVER))
	$(MAKE) -C $(PRAWNOS_BOOTLOADER_UBOOT_PACKAGE_IMAGE) install INSTALL_TARGET=$(PRAWNOS_BUILD)
else
  echo "No bootloader package to install for target ${TARGET}"
endif


### CLEAN RULES

.PHONY: clean_bootloader
clean_bootloader:
	rm -rf $(PRAWNOS_BOOTLOADER_BUILD)


### REAL RULES

$(BOOTLOADER_EXTRACTED):
## TODO: just use the git repo for arm64-rk3588 for now
ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
	git clone git@github.com:SolidHal/rk3588-u-boot.git $(PRAWNOS_BOOTLOADER_BUILD)
	touch $(BOOTLOADER_EXTRACTED)
else
  echo "No bootloader source to extract for target ${TARGET}"
endif

# TODO: once uboot is buildable, do that instead
# $(PRAWNOS_BOOTLOADER_BUILT): $(BOOTLOADER_EXTRACTED)
# 	rm -rf $(BOOTLOADER_BUILD_LOG)
# 	$(PRAWNOS_BOOTLOADER_SCRIPTS_BUILD_UBOOT) $(UBOOTVER) $(PRAWNOS_BOOTLOADER_RESOURCES) $(PRAWNOS_BOOTLOADER_BUILD) $(BOOTLOADER_CONFIG) 2>&1 | tee $(BOOTLOADER_BUILD_LOG)


$(PRAWNOS_BOOTLOADER_BUILT):
	echo "WARNING: Using prebuilt uboot image for now..."
	mkdir -p $(PRAWNOS_BOOTLOADER_BUILD)
	wget $(WGET_OPTS) https://github.com/SolidHal/itx-3588j-u-boot/releases/download/head/uboot.img -O $(PRAWNOS_BOOTLOADER_BUILT)

endif ## BOOTLOADER_MK
