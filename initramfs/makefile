ifndef INITRAMFS_MK
INITRAMFS_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

INITRAMFS_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/initramfs-log.txt

INITRAMFS_RESOURCES := $(PRAWNOS_INITRAMFS)/resources

.PHONY: initramfs initramfs_clean

initramfs: $(PRAWNOS_INITRAMFS_IMAGE)

initramfs_clean:
	rm -f $(PRAWNOS_INITRAMFS)

$(PRAWNOS_INITRAMFS_IMAGE):
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	rm -rf $(INITRAMFS_BUILD_LOG)
	$(PRAWNOS_INITRAMFS_SCRIPTS_BUILD) $(PRAWNOS_IMAGE_BASE) $(INITRAMFS_RESOURCES) $(PRAWNOS_BUILD) $(TARGET) 2>&1 | tee $(INITRAMFS_BUILD_LOG)

endif
