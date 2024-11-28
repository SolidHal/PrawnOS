.DEFAULT_GOAL := default
#import all shared make vars
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

ifneq ($(TARGET),$(PRAWNOS_ARM64))
$(error Cant build arm64 kernel package with non arm64 target)
endif

ifneq ($(KERNEL_TYPE),$(PRAWNOS_HYBRID_KERNEL))
$(error Cant build arm64 hybrid kernel package with KERNEL_TYPE not set to hybrid-kernel)
endif

#package specific vars
DEB_VERSION := $(PRAWNOS_KERNEL_IMAGE_CAT_DEB_VER)
PRAWNOS_VERSION := $(PRAWNOS_KERNEL_IMAGE_CAT_PRAWNOS_VER)
PACKAGE := prawnos-linux-image-blobby-arm64
PACKAGE_ARCH := arm64

#uses the full debian version for the package name
PACKAGE_NAME :=  $(PACKAGE)_$(DEB_VERSION)_$(PACKAGE_ARCH)
PACKAGE_NAME_DEB := $(PACKAGE_NAME).deb
#uses only the upstream kernel version for the orig tar
PACKAGE_NAME_ORIG := $(PACKAGE)_$(PRAWNOS_VERSION)
PACKAGE_NAME_ORIG_TAR = $(PACKAGE_NAME_ORIG).orig.tar.gz
PACKAGE_NAME_ORIG_DIR = $(PACKAGE)_$(KVER)-$(PRAWNOS_KERNEL_VER)-orig

ORIG := $(PRAWNOS_BUILD)/$(PACKAGE_NAME_ORIG_DIR)

default: $(PACKAGE_NAME_DEB)


$(PACKAGE_NAME_DEB): $(PACKAGE_NAME_ORIG_TAR)
	@echo Building $@
	$(PRAWNOS_PACKAGE_SCRIPTS_UPDATE_DEB_FILES) $(PRAWNOS_KERNEL_PACKAGE_IMAGE)/src $(DEB_VERSION)
	$(PRAWNOS_PACKAGE_SCRIPTS_PBUILD) $(PACKAGE_NAME_DEB) \
                                            $(PBUILDER_VARS) \
                                            $(PRAWNOS_LOCAL_APT_VARS) \
                                            $(PACKAGE_LOCAL_BUILD_DEPS)

$(PACKAGE_NAME_ORIG_TAR):
	make -f $(PRAWNOS_KERNEL)/makefile kernel
	rm -rf $(ORIG)
	rm -f $(PACKAGE)_*-*.orig.tar.gz
	mkdir $(ORIG)
	cp $(PRAWNOS_KERNEL_BUILT) $(ORIG)/$(PACKAGE_NAME_ORIG)
	cp $(PRAWNOS_KERNEL_RESOURCES_SHARED)/FlashKernelPartition.sh $(ORIG)/
	tar -czf $(PACKAGE_NAME_ORIG_TAR) -C $(ORIG)/ .


.PHONY: clean
clean:
	rm -rf *.upload
	rm -rf *.deb
	rm -rf *.changes
	rm -rf *.dsc
	rm -rf *.build
	rm -rf *.diff.gz
	rm -rf *.debian.tar.xz
	rm -rf *.buildinfo
	rm -f src/debian/debhelper-build-stamp
	rm -rf src/debian/$(PACKAGE)*
	rm -f src/debian/files
	rm -rf src/debian/.debhelper
	rm -f $(PACKAGE)_*-*.orig.tar.gz
	rm -rf $(ORIG)

.PHONY: install
install:
	$(PRAWNOS_PACKAGE_SCRIPTS_INSTALL) $(PACKAGE_NAME_DEB) $(INSTALL_TARGET)
	$(PRAWNOS_IMAGE_SCRIPTS_INSTALL_KERNEL) $(KVER) $(PRAWNOS_IMAGE) $(TARGET) $(PRAWNOS_KERNEL_BUILD) $(PRAWNOS_BUILD) $(PACKAGE) $(PACKAGE_NAME_DEB)

.PHONY: upload
upload:
	$(PRAWNOS_PACKAGE_SCRIPTS_UPLOAD) $(PACKAGE_NAME).changes
