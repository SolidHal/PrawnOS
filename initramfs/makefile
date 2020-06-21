ifndef INITRAMFS_MK
INITRAMFS_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

INITRAMFS_RESOURCES := $(PRAWNOS_PACKAGE_INITRAMFS)/resources

.PHONY: initramfs initramfs_clean

initramfs: $(PRAWNOS_INITRAMFS)

initramfs_clean:
	rm -f $(PRAWNOS_INITRAMFS)

$(PRAWNOS_INITRAMFS):
	$(PRAWNOS_INITRAMFS_SCRIPTS_BUILD) $(PRAWNOS_IMAGE_BASE) $(INITRAMFS_RESOURCES) $(PRAWNOS_BUILD)

endif
