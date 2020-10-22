ifndef INITRAMFS_MK
INITRAMFS_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

INITRAMFS_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/initramfs-log.txt

INITRAMFS_RESOURCES := $(PRAWNOS_INITRAMFS)/resources

.PHONY: initramfs clean_initramfs

initramfs: $(PRAWNOS_INITRAMFS_IMAGE)

clean_initramfs:
	rm -f $(PRAWNOS_INITRAMFS_IMAGE)

$(PRAWNOS_INITRAMFS_IMAGE): | $(PRAWNOS_BUILD_LOGS)
	rm -rf $(INITRAMFS_BUILD_LOG)
	$(PRAWNOS_INITRAMFS_SCRIPTS_BUILD) $(PRAWNOS_IMAGE_BASE) $(INITRAMFS_RESOURCES) $(PRAWNOS_BUILD) $(TARGET) 2>&1 | tee $(INITRAMFS_BUILD_LOG)

endif
