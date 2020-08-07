ifndef KERNEL_MK
KERNEL_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

KERNEL_PATCHED := $(PRAWNOS_KERNEL_BUILD)/.kernel_patched
KERNEL_EXTRACTED := $(PRAWNOS_KERNEL_BUILD)/.kernel_extracted
ATH9K_EXTRACTED := $(PRAWNOS_ATH9K_BUILD)/.ath9k_extracted

KERNEL_RESOURCES := $(PRAWNOS_KERNEL)/resources
KERNEL_SOURCES := $(PRAWNOS_KERNEL)/sources
KERNEL_PATCHES := $(PRAWNOS_KERNEL)/patches

KERNEL_TAR := $(KERNEL_SOURCES)/linux-libre-$(KVER)-gnu.tar.lz
KERNEL_TAR_SIGNATURE := $(KERNEL_TAR).sign
KERNEL_BUILT := $(PRAWNOS_KERNEL_BUILD)/vmlinux.kpart

KERNEL_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/kernel-log.txt

ATH9K_TAR := $(KERNEL_SOURCES)/open-ath9k-htc-firmware.tar.gz
ATH9K := open-ath9k-htc-firmware
ATH9K_BUILT := $(PRAWNOS_ATH9K_BUILD)/target_firmware/htc_9271.fw

### PHONY TARGETS
.PHONY: kernel
kernel: $(KERNEL_BUILT)

.PHONY: ath9k
ath9k: $(ATH9K_BUILT)

.PHONY: patch_kernel
patch_kernel: $(KERNEL_PATCHED)

.PHONY: extract_kernel
extract_kernel: $(KERNEL_EXTRACTED)

.PHONY: extract_ath9k
extract_ath9k: $(ATH9K_EXTRACTED)

.PHONY: package_kernel
packages: kernel
	@echo TODO

### CLEAN TARGETS

.PHONY: clean_kernel
clean_kernel:
	rm -rf $(PRAWNOS_KERNEL_BUILD)

.PHONY: clean_ath9k
clean_ath9k:
	rm -rf $(PRAWNOS_ATH9K_BUILD)

### DEVELOPER TARGETS

.PHONY: update_ath9k_tar
update_ath9k_tar:
	mkdir -p tmp/$(ATH9K)
	git clone --depth 1 https://github.com/qca/open-ath9k-htc-firmware.git tmp/$(ATH9K)
	cd tmp && tar czvf $(ATH9K_SOURCE) $(ATH9K)
	rm -rf tmp/

.PHONY: update_kernel_sig
update_kernel_sig:
	wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz.sign -O $(KERNEL_TAR_SIGNATURE)

### REAL TARGETS

$(KERNEL_TAR_SIGNATURE): | $(KERNEL_SOURCES)
	wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz.sign -O $(KERNEL_TAR_SIGNATURE)

$(KERNEL_TAR): | $(KERNEL_SOURCES)
	wget https://www.linux-libre.fsfla.org/pub/linux-libre/releases/$(KVER)-gnu/linux-libre-$(KVER)-gnu.tar.lz -O $(KERNEL_TAR)

$(KERNEL_EXTRACTED): $(KERNEL_TAR) $(KERNEL_TAR_SIGNATURE) | $(PRAWNOS_BUILD)
	gpg --import $(KERNEL_RESOURCES)/linux-libre-signing-key.gpg
	gpg --verify $(KERNEL_TAR_SIGNATURE) $(KERNEL_TAR)
	tar --lzip -xvf $(KERNEL_TAR) -C $(PRAWNOS_BUILD)
	touch $(KERNEL_EXTRACTED)

$(ATH9K_EXTRACTED): | $(PRAWNOS_BUILD)
	tar -xvf $(ATH9K_TAR) -C $(PRAWNOS_BUILD)
	touch $(ATH9K_EXTRACTED)

$(KERNEL_PATCHED): $(KERNEL_EXTRACTED)
	@echo $(PRAWNOS_KERNEL_BUILD)
	$(PRAWNOS_KERNEL_SCRIPTS_PATCH) $(KVER) $(KERNEL_PATCHES) $(PRAWNOS_KERNEL_BUILD)
	touch $(KERNEL_PATCHED)

$(ATH9K_BUILT): $(ATH9K_EXTRACTED)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD_ATH9K) $(PRAWNOS_ATH9K_BUILD)

$(KERNEL_BUILT): $(KERNEL_EXTRACTED) $(KERNEL_PATCHED) $(ATH9K_BUILT)
	make -C $(PRAWNOS_INITRAMFS)
	rm -rf $(KERNEL_BUILD_LOG)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD) $(KVER) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(PRAWNOS_INITRAMFS_IMAGE) 2>&1 | tee $(KERNEL_BUILD_LOG)

endif
