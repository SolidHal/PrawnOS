ifndef INITRAMFS_MK
INITRAMFS_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

INITRAMFS_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/initramfs-log.txt

ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
INITRAMFS_RESOURCES := $(PRAWNOS_INITRAMFS)/resources/$(TARGET)
else
INITRAMFS_RESOURCES := $(PRAWNOS_INITRAMFS)/resources
endif

.PHONY: initramfs clean_initramfs

initramfs: $(PRAWNOS_INITRAMFS_IMAGE)

clean_initramfs:
	rm -f $(PRAWNOS_INITRAMFS_IMAGE)
ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
# on uboot platforms, the initramfs is part of the kernel package
# so only the kernel package must be rebuilt
	$(MAKE) -C $(PRAWNOS_KERNEL_PACKAGE_IMAGE) clean
else
# on non-uboot platforms, the initramfs is baked into the kernel image
# so the whole kernel must also be cleaned
	$(MAKE) -C $(PRAWNOS_KERNEL) clean_kernel
endif

$(PRAWNOS_INITRAMFS_IMAGE): | $(PRAWNOS_BUILD_LOGS)
	rm -rf $(INITRAMFS_BUILD_LOG)
	$(PRAWNOS_INITRAMFS_SCRIPTS_BUILD) $(PRAWNOS_IMAGE_BASE) $(INITRAMFS_RESOURCES) $(PRAWNOS_BUILD) $(TARGET) 2>&1 | tee $(INITRAMFS_BUILD_LOG)

endif
