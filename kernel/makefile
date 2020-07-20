ifndef KERNEL_MK
KERNEL_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

### TARGETED VARS ###
KERNEL_PATCHED := $(PRAWNOS_KERNEL_BUILD)/.kernel_patched
KERNEL_EXTRACTED := $(PRAWNOS_KERNEL_BUILD)/.kernel_extracted

KERNEL_RESOURCES := $(PRAWNOS_KERNEL)/resources/$(TARGET)
KERNEL_PATCHES := $(PRAWNOS_KERNEL)/patches/$(TARGET)

KERNEL_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/kernel-log-$(TARGET).txt

### UNIVERSAL VARS ###
KERNEL_SOURCES := $(PRAWNOS_KERNEL)/sources
KERNEL_TAR := $(KERNEL_SOURCES)/linux-libre-$(KVER)-gnu.tar.lz
KERNEL_TAR_SIGNATURE := $(KERNEL_TAR).sign

ATH9K_EXTRACTED := $(PRAWNOS_ATH9K_BUILD)/.ath9k_extracted
ATH9K_TAR := $(KERNEL_SOURCES)/open-ath9k-htc-firmware.tar.gz
ATH9K := open-ath9k-htc-firmware
ATH9K_9271_FW := $(PRAWNOS_ATH9K_BUILD)/target_firmware/htc_9271.fw
ATH95_7010_FW := $(PRAWNOS_ATH9K_BUILD)/target_firmware/htc_7010.fw
ATH9K_BUILT := $(ATH9K_9271_FW)

KERNEL_ATH9K_FIRMWARES := $(PRAWNOS_KERNEL_BUILD)/open-ath9k-firmware

KERNEL_ATH9K_INSTALLED := $(KERNEL_ATH9K_FIRMWARES)/htc_9271.fw

### PHONY RULES
.PHONY: kernel
kernel: $(PRAWNOS_KERNEL_BUILT)

.PHONY: ath9k
ath9k: $(ATH9K_BUILT)

.PHONY: patch_kernel
patch_kernel: $(KERNEL_PATCHED)

.PHONY: extract_kernel
extract_kernel: $(KERNEL_EXTRACTED)

.PHONY: extract_ath9k
extract_ath9k: $(ATH9K_EXTRACTED)

.PHONY: kernel_image_package
kernel_image_package: $(PRAWNOS_KERNEL_BUILT)
	$(MAKE) -C $(PRAWNOS_KERNEL_PACKAGE_IMAGE)
	$(MAKE) -C $(PRAWNOS_KERNEL_PACKAGE_IMAGE) install INSTALL_TARGET=$(PRAWNOS_BUILD)

.PHONY: kernel_config
kernel_config: $(KERNEL_PATCHED)
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	$(PRAWNOS_KERNEL_SCRIPTS_MENUCONFIG) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(TARGET)

### CLEAN RULES

.PHONY: clean_kernel
clean_kernel:
	rm -rf $(PRAWNOS_KERNEL_BUILD)

.PHONY: clean_ath9k
clean_ath9k:
	rm -rf $(PRAWNOS_ATH9K_BUILD)

### DEVELOPER RULES

.PHONY: update_ath9k_tar
update_ath9k_tar:
	mkdir -p tmp/$(ATH9K)
	git clone --depth 1 https://github.com/qca/open-ath9k-htc-firmware.git tmp/$(ATH9K)
	cd tmp && tar czvf $(ATH9K_SOURCE) $(ATH9K)
	rm -rf tmp/

.PHONY: update_kernel_sig
update_kernel_sig:
	wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz.sign -O $(KERNEL_TAR_SIGNATURE)

### REAL RULES

$(KERNEL_TAR):
	wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz -O $(KERNEL_TAR)
	gpg --import $(KERNEL_SOURCES)/linux-libre-signing-key.gpg
	gpg --verify $(KERNEL_TAR_SIGNATURE) $(KERNEL_TAR)

$(KERNEL_EXTRACTED): $(KERNEL_TAR)
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	tar --lzip -xvf $(KERNEL_TAR) -C $(PRAWNOS_BUILD)
	touch $(KERNEL_EXTRACTED)

$(KERNEL_PATCHED): $(KERNEL_EXTRACTED)
	@echo $(PRAWNOS_KERNEL_BUILD)
	$(PRAWNOS_KERNEL_SCRIPTS_PATCH) $(KVER) $(KERNEL_PATCHES) $(PRAWNOS_KERNEL_BUILD) $(TARGET)
	touch $(KERNEL_PATCHED)

$(ATH9K_EXTRACTED):
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	tar -xvf $(ATH9K_TAR) -C $(PRAWNOS_BUILD)
	touch $(ATH9K_EXTRACTED)

$(ATH9K_BUILT): $(ATH9K_EXTRACTED)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD_ATH9K) $(PRAWNOS_ATH9K_BUILD)

$(KERNEL_ATH9K_INSTALLED): $(KERNEL_PATCHED) $(ATH9K_BUILT)
	mkdir -p $(KERNEL_ATH9K_FIRMWARES)
	cp $(ATH9K_9271_FW) $(ATH9K_7010_FW) $(KERNEL_ATH9K_FIRMWARES)/

$(PRAWNOS_KERNEL_BUILT): $(KERNEL_ATH9K_INSTALLED)
	$(MAKE) -C $(PRAWNOS_INITRAMFS)
	rm -rf $(KERNEL_BUILD_LOG)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD) $(KVER) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(PRAWNOS_INITRAMFS_IMAGE) $(TARGET) 2>&1 | tee $(KERNEL_BUILD_LOG)

endif
