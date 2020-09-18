ifndef KERNEL_MK
KERNEL_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk
include $(PRAWNOS_ROOT)/initramfs/makefile

### TARGETED VARS ###
KERNEL_PATCHED := $(PRAWNOS_KERNEL_BUILD)/.kernel_patched
KERNEL_EXTRACTED := $(PRAWNOS_KERNEL_BUILD)/.kernel_extracted

KERNEL_SHARED_RESOURCES := $(PRAWNOS_KERNEL)/resources/shared
KERNEL_RESOURCES := $(PRAWNOS_KERNEL)/resources/$(TARGET)
KERNEL_PATCHES := $(PRAWNOS_KERNEL)/patches/$(TARGET)

KERNEL_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/kernel-log-$(TARGET).txt

### UNIVERSAL VARS ###
KERNEL_TAR := $(PRAWNOS_BUILD_SOURCES)/linux-libre-$(KVER)-gnu.tar.lz
KERNEL_TAR_SIGNATURE := $(KERNEL_TAR).sign
KERNEL_LINUX_LIBRE_PUB := $(KERNEL_SHARED_RESOURCES)/linux-libre-signing-key.gpg

ATH9K_EXTRACTED := $(PRAWNOS_ATH9K_BUILD)/.ath9k_extracted
ATH9K_TAR := $(KERNEL_SHARED_RESOURCES)/open-ath9k-htc-firmware.tar.gz
ATH9K := open-ath9k-htc-firmware
ATH9K_9271_FW := $(PRAWNOS_ATH9K_BUILD)/target_firmware/htc_9271.fw
ATH9K_7010_FW := $(PRAWNOS_ATH9K_BUILD)/target_firmware/htc_7010.fw
ATH9K_BUILT := $(ATH9K_9271_FW)
ATH9K_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/ath9k-log.txt

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

### REAL RULES

$(KERNEL_ATH9K_FIRMWARES):
	mkdir -p $(KERNEL_ATH9K_FIRMWARES)

$(KERNEL_TAR_SIGNATURE): | $(PRAWNOS_BUILD_SOURCES)
	wget $(WGET_OPTS) https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz.sign -O $(KERNEL_TAR_SIGNATURE)

$(KERNEL_TAR): $(KERNEL_TAR_SIGNATURE) | $(PRAWNOS_BUILD_LOGS) $(PRAWNOS_BUILD_SOURCES)
	wget $(WGET_OPTS) https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz -O $(KERNEL_TAR)
	gpg --import $(KERNEL_LINUX_LIBRE_PUB)
	gpg --verify $(KERNEL_TAR_SIGNATURE) $(KERNEL_TAR)

$(KERNEL_EXTRACTED): $(KERNEL_TAR)
	tar --lzip -xvf $(KERNEL_TAR) -C $(PRAWNOS_BUILD)
	touch $(KERNEL_EXTRACTED)

$(KERNEL_PATCHED): $(KERNEL_EXTRACTED)
	@echo $(PRAWNOS_KERNEL_BUILD)
	$(PRAWNOS_KERNEL_SCRIPTS_PATCH) $(KVER) $(KERNEL_PATCHES) $(PRAWNOS_KERNEL_BUILD) $(TARGET)
	touch $(KERNEL_PATCHED)

$(ATH9K_EXTRACTED): | $(PRAWNOS_BUILD_LOGS) $(PRAWNOS_BUILD_SOURCES) $(PRAWNOS_BUILD_SHARED)
	tar -xvf $(ATH9K_TAR) -C $(PRAWNOS_BUILD_SHARED)
	touch $(ATH9K_EXTRACTED)

$(ATH9K_BUILT): $(ATH9K_EXTRACTED)
	rm -rf $(ATH9K_BUILD_LOG)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD_ATH9K) $(PRAWNOS_ATH9K_BUILD) 2>&1 | tee $(ATH9K_BUILD_LOG)

$(KERNEL_ATH9K_INSTALLED): $(KERNEL_PATCHED) $(ATH9K_BUILT) | $(KERNEL_ATH9K_FIRMWARES)
	cp $(ATH9K_9271_FW) $(KERNEL_ATH9K_FIRMWARES)/
	cp $(ATH9K_7010_FW) $(KERNEL_ATH9K_FIRMWARES)/

$(PRAWNOS_KERNEL_BUILT): $(KERNEL_ATH9K_INSTALLED) $(PRAWNOS_INITRAMFS_IMAGE)
	rm -rf $(KERNEL_BUILD_LOG)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD) $(KVER) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(PRAWNOS_INITRAMFS_IMAGE) $(TARGET) 2>&1 | tee $(KERNEL_BUILD_LOG)

endif
