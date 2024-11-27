ifndef BUILD_COMMON_MK
BUILD_COMMON_MK := 1


### PRAWNOS TARGET ARCHS
PRAWNOS_ARMHF := armhf
PRAWNOS_ARM64 := arm64
PRAWNOS_ARM64_RK3588_SERVER := arm64-rk3588-server
PRAWNOS_ARM64_RK3588 := arm64-rk3588

# validate that target is set to something we support
ifeq ($(TARGET),$(PRAWNOS_ARMHF))
$(info TARGET is $(PRAWNOS_ARMHF))
TARGET_ARCH=armhf
else ifeq ($(TARGET),$(PRAWNOS_ARM64))
$(info TARGET is $(PRAWNOS_ARM64))
TARGET_ARCH=arm64
else ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
$(info TARGET is $(PRAWNOS_ARM64_RK3588_SERVER))
TARGET_ARCH=arm64
else ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588))
$(info TARGET is $(PRAWNOS_ARM64_RK3588))
TARGET_ARCH=arm64
else
$(info TARGET is invalid)
$(info Must specify a TARGET. Valid TARGETS are)
$(info TARGET=armhf (Asus c201 aka veyron speedy, Asus c100 aka veyron minnie))
$(info TARGET=arm64 (Asus c101 aka gru bob, Samsung Chromebook Plus aka gru kevin))
$(info TARGET=arm64-rk3588-server (Firefly ITX-3588J))
$(info TARGET=arm64-rk3588 (Firefly ROC-3588S-PC))
$(error Set a valid TARGET)
endif

export $(TARGET)


### PRAWNOS KERNEL TYPES
PRAWNOS_LIBRE_KERNEL := libre
PRAWNOS_HYBRID_KERNEL := hybrid
PRAWNOS_BLOBBY_KERNEL := blobby

# hybrid kernel is Blobby wifi and bluetooth in an otherwise libre kernel
# As ATH9k devices and 2.4GHZ wifi become less commonly available, and no new wifi adapters with fully open
# source firmware and drivers have become available, its hard to stick to using blob-free wifi
# Let users compromise by re-adding blobby wifi to their otherwise blob-free kernel

# validate that KERNEL_TYPE is set to something we support
ifeq ($(KERNEL_TYPE),$(PRAWNOS_LIBRE_KERNEL))
$(info KERNEL_TYPE is $(PRAWNOS_LIBRE_KERNEL))
else ifeq ($(KERNEL_TYPE),$(PRAWNOS_HYBRID_KERNEL))
$(info KERNEL_TYPE is $(PRAWNOS_HYBRID_KERNEL))
else ifeq ($(KERNEL_TYPE),$(PRAWNOS_BLOBBY_KERNEL))
$(info KERNEL_TYPE is $(PRAWNOS_BLOBBY_KERNEL))
else
$(info KERNEL_TYPE is invalid)
$(info Must specify a KERNEL_TYPE. Valid KERNEL_TYPEs are)
$(info KERNEL_TYPE=libre (The fully deblobbed linux kernel))
$(info KERNEL_TYPE=hybrid (The deblobbed linux kenrel, but with blobs for wifi re-added))
$(info KERNEL_TYPE=blobby (The normal linux kenrel, with all of its usual blobs))
$(error Set a valid KERNEL_TYPE)
endif

export $(KERNEL_TYPE)

#Place all shared make vars below
#=========================================================================================
### GLOBALS

#KVER
# upstream kernel version
# when this is changed, PRAWNOS_KERNEL_VER, PRAWNOS_KERNEL_HEADERS_DEBVER, and PRAWNOS_KERNEL_IMAGE_DEBVER should be reset to 1

#PRAWNOS_KERNEL_VER
# the version of the prawnos linux kernel. This is incremented whenever changes to the config or patches are made, but the KVER stays the same
# when this is incremented, PRAWNOS_KERNEL_IMAGE_DEBVER, and PRAWNOS_KERNEL_HEADERS_DEBVER should be reset to 1

#PRAWNOS_KERNEL_IMAGE_DEBVER
# the version of the prawnos image deb package. This should be incremented with each rebuild/upload of the same KVER and PRAWNOS_KERNEL_IMAGE_VER

#PRAWNOS_KERNEL_HEADERS_DEBVER
# the version of the prawnos headers deb package. This should be incremented with each rebuild/upload of the same KVER and PRAWNOS_KERNEL_IMAGE_VER

## ARMHF KERNEL VERSIONS
ifeq ($(TARGET),$(PRAWNOS_ARMHF))
KVER := 5.15.6
PRAWNOS_KERNEL_VER := 1
PRAWNOS_KERNEL_IMAGE_DEBVER := 1
PRAWNOS_KERNEL_HEADERS_DEBVER := 1

## ARM64 KERNEL VERSIONS
else ifeq ($(TARGET),$(PRAWNOS_ARM64))
KVER := 6.6.60
PRAWNOS_KERNEL_VER := 1
PRAWNOS_KERNEL_IMAGE_DEBVER := 1
PRAWNOS_KERNEL_HEADERS_DEBVER := 1

## ARM64_RK3588_SERVER KERNEL VERSIONS
else ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
KVER := 5.19.5
PRAWNOS_KERNEL_VER := 1
PRAWNOS_KERNEL_IMAGE_DEBVER := 2
PRAWNOS_KERNEL_HEADERS_DEBVER := 1

## ARM64_RK3588 KERNEL VERSIONS
else ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588))
KVER := 5.19.5
PRAWNOS_KERNEL_VER := 1
PRAWNOS_KERNEL_IMAGE_DEBVER := 1
PRAWNOS_KERNEL_HEADERS_DEBVER := 1
endif

ifdef PRAWNOS_KVER
## Override KVER with the value of global $PRAWNOS_KVER if it's set.
## This allows the caller to explicitly select the desired KVER
## by injecting it via "export PRAWNOS_KVER=w.x.y".
## and not depending on the hard-coded version number here above.
KVER := $(PRAWNOS_KVER)
#Offset the kernel package versions to avoid future collision if we end up using
#the specified KVER
PRAWNOS_KERNEL_VER := 200
PRAWNOS_KERNEL_IMAGE_DEBVER := 1
PRAWNOS_KERNEL_HEADERS_DEBVER := 1
endif

PRAWNOS_KERNEL_IMAGE_CAT_PRAWNOS_VER=$(KVER)-$(PRAWNOS_KERNEL_VER)
PRAWNOS_KERNEL_IMAGE_CAT_DEB_VER=$(KVER)-$(PRAWNOS_KERNEL_VER)-$(PRAWNOS_KERNEL_IMAGE_DEBVER)
PRAWNOS_KERNEL_HEADERS_CAT_PRAWNOS_VER=$(KVER)-$(PRAWNOS_KERNEL_VER)
PRAWNOS_KERNEL_HEADERS_CAT_DEB_VER=$(KVER)-$(PRAWNOS_KERNEL_VER)-$(PRAWNOS_KERNEL_HEADERS_DEBVER)


## ARM64_RK3588_SERVER BOOTLOADER VERSIONS
ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
UBOOTVER := 2023.01-rc1
BOOTLOADERVER := $(UBOOTVER)
PRAWNOS_BOOTLOADER_VER := 1
PRAWNOS_BOOTLOADER_IMAGE_DEBVER := 1
endif

## ARM64_RK3588 BOOTLOADER VERSIONS
ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588))
UBOOTVER := 2023.01-rc1
BOOTLOADERVER := $(UBOOTVER)
PRAWNOS_BOOTLOADER_VER := 1
PRAWNOS_BOOTLOADER_IMAGE_DEBVER := 1
endif


PRAWNOS_BOOTLOADER_IMAGE_CAT_PRAWNOS_VER=$(BOOTLOADERVER)-$(PRAWNOS_BOOTLOADER_VER)
PRAWNOS_BOOTLOADER_IMAGE_CAT_DEB_VER=$(BOOTLOADERVER)-$(PRAWNOS_BOOTLOADER_VER)-$(PRAWNOS_BOOTLOADER_IMAGE_DEBVER)

# Otherwise errors are ignored when output is piped to tee:
SHELL := /bin/bash -o pipefail


### PRAWNOS CORE DIRECTORIES
PRAWNOS_BUILD := $(PRAWNOS_ROOT)/build/$(TARGET)

PRAWNOS_BUILD_SHARED := $(PRAWNOS_ROOT)/build/shared

PRAWNOS_SCRIPTS := $(PRAWNOS_ROOT)/scripts

PRAWNOS_KERNEL := $(PRAWNOS_ROOT)/kernel

PRAWNOS_INITRAMFS := $(PRAWNOS_ROOT)/initramfs

PRAWNOS_FILESYSTEM := $(PRAWNOS_ROOT)/filesystem

PRAWNOS_BOOTLOADER := $(PRAWNOS_ROOT)/bootloader

### BUILD DIRS

PRAWNOS_BUILD_LOGS := $(PRAWNOS_BUILD)/logs
PRAWNOS_BUILD_SOURCES := $(PRAWNOS_BUILD)/sources
PRAWNOS_BUILD_DEBOOTSTRAP_APT_CACHE := $(PRAWNOS_BUILD)/debootstrap-apt-cache
PRAWNOS_BUILD_CHROOT_APT_CACHE := $(PRAWNOS_BUILD)/chroot-apt-cache
PRAWNOS_LOCAL_APT_REPO := $(PRAWNOS_BUILD)/prawnos-local-apt-repo

### PRAWNOS IMAGES
ifeq ($(DEBIAN_SUITE),)
DEBIAN_SUITE := bookworm
endif
ifeq ($(PRAWNOS_SUITE),)
PRAWNOS_SUITE := Shiba
endif

PRAWNOS_GIT_SHA := $(shell git rev-parse HEAD)

PRAWNOS_IMAGE := $(PRAWNOS_ROOT)/PrawnOS-$(PRAWNOS_SUITE)-$(TARGET)-$(KERNEL_TYPE).img
PRAWNOS_IMAGE_GIT := $(PRAWNOS_ROOT)/PrawnOS-$(PRAWNOS_SUITE)-$(TARGET)-git-$(PRAWNOS_GIT_SHA).img
PRAWNOS_IMAGE_GIT_GZ := $(PRAWNOS_IMAGE_GIT).gz
PRAWNOS_IMAGE_BASE := $(PRAWNOS_IMAGE)-BASE

### BUILD SCRIPTS
PRAWNOS_BUILD_SCRIPTS := $(PRAWNOS_SCRIPTS)/BuildScripts

PRAWNOS_FILESYSTEM_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/FilesystemScripts
PRAWNOS_FILESYSTEM_SCRIPTS_BUILD := $(PRAWNOS_FILESYSTEM_SCRIPTS)/buildFilesystem.sh

PRAWNOS_KERNEL_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/KernelScripts
PRAWNOS_KERNEL_SCRIPTS_BUILD := $(PRAWNOS_KERNEL_SCRIPTS)/buildKernel.sh
PRAWNOS_KERNEL_SCRIPTS_MENUCONFIG := $(PRAWNOS_KERNEL_SCRIPTS)/crossMenuConfig.sh
PRAWNOS_KERNEL_SCRIPTS_GENERATE_CONFIG := $(PRAWNOS_KERNEL_SCRIPTS)/generateConfig.sh
PRAWNOS_KERNEL_SCRIPTS_PATCH := $(PRAWNOS_KERNEL_SCRIPTS)/patchKernel.sh
PRAWNOS_KERNEL_SCRIPTS_PERF := $(PRAWNOS_KERNEL_SCRIPTS)/buildPerf.sh
PRAWNOS_KERNEL_SCRIPTS_BUILD_ATH9K := $(PRAWNOS_KERNEL_SCRIPTS)/buildAth9k.sh
PRAWNOS_KERNEL_SCRIPTS_EXTRACT_REGDB := $(PRAWNOS_KERNEL_SCRIPTS)/extractRegdb.sh

PRAWNOS_BOOTLOADER_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/BootloaderScripts
PRAWNOS_BOOTLOADER_SCRIPTS_BUILD_UBOOT := $(PRAWNOS_BOOTLOADER_SCRIPTS)/buildUboot.sh

PRAWNOS_IMAGE_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/ImageScripts
PRAWNOS_IMAGE_SCRIPTS_INSTALL_KERNEL := $(PRAWNOS_IMAGE_SCRIPTS)/installKernelToFs.sh
PRAWNOS_IMAGE_SCRIPTS_INSTALL_BOOTLOADER := $(PRAWNOS_IMAGE_SCRIPTS)/installBootloaderToFs.sh
PRAWNOS_IMAGE_SCRIPTS_WRITE_IMAGE := $(PRAWNOS_IMAGE_SCRIPTS)/writeImage.sh

PRAWNOS_INITRAMFS_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/InitramfsScripts
PRAWNOS_INITRAMFS_SCRIPTS_BUILD := $(PRAWNOS_INITRAMFS_SCRIPTS)/buildInitramFs.sh

PRAWNOS_PACKAGE_SCRIPTS := $(PRAWNOS_BUILD_SCRIPTS)/PackageScripts
PRAWNOS_PACKAGE_SCRIPTS_INSTALL := $(PRAWNOS_PACKAGE_SCRIPTS)/installPackage.sh
PRAWNOS_PACKAGE_SCRIPTS_PBUILD := $(PRAWNOS_PACKAGE_SCRIPTS)/pbuildPackage.sh
PRAWNOS_PACKAGE_SCRIPTS_UPLOAD := $(PRAWNOS_PACKAGE_SCRIPTS)/uploadPackage.sh
PRAWNOS_PACKAGE_SCRIPTS_UPDATE_DEB_FILES := $(PRAWNOS_PACKAGE_SCRIPTS)/updateImagePackageDebfile.sh

### INSTALL SCRIPTS
PRAWNOS_INSTALL_SCRIPTS := $(PRAWNOS_SCRIPTS)/InstallScripts

### SHARED SCRIPTS
PRAWNOS_SHARED_SCRIPTS := $(PRAWNOS_SCRIPTS)/Shared

PRAWNOS_SHARED_SCRIPTS_PACKAGE_LISTS := $(PRAWNOS_SHARED_SCRIPTS)/package_lists.sh

### FILESYSTEM RESOURCES
PRAWNOS_FILESYSTEM_RESOURCES := $(PRAWNOS_FILESYSTEM)/resources
PRAWNOS_FILESYSTEM_PACKAGES := $(PRAWNOS_FILESYSTEM)/packages


### PBUILDER RESOURCES
PBUILDER_DIR := $(PRAWNOS_FILESYSTEM_RESOURCES)/pbuilder

ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
PBUILDER_CHROOT := $(PRAWNOS_BUILD)/prawnos-pbuilder-$(PRAWNOS_ARM64)-base.tgz
PBUILDER_RC := $(PBUILDER_DIR)/prawnos-pbuilder-$(PRAWNOS_ARM64).rc
else ifeq ($(TARGET),$(PRAWNOS_ARM64_RK3588_SERVER))
PBUILDER_CHROOT := $(PRAWNOS_BUILD)/prawnos-pbuilder-$(PRAWNOS_ARM64)-base.tgz
PBUILDER_RC := $(PBUILDER_DIR)/prawnos-pbuilder-$(PRAWNOS_ARM64).rc
else
PBUILDER_CHROOT := $(PRAWNOS_BUILD)/prawnos-pbuilder-$(TARGET)-base.tgz
PBUILDER_RC := $(PBUILDER_DIR)/prawnos-pbuilder-$(TARGET).rc
endif

PBUILDER_HOOKS := $(PBUILDER_DIR)/hooks
PBUILDER_VARS := $(PBUILDER_CHROOT) $(PBUILDER_RC) $(PBUILDER_HOOKS)

### LOCAL APT RESOURCES
PRAWNOS_LOCAL_APT_SOURCE := "deb [trusted=yes] file://$(PRAWNOS_LOCAL_APT_REPO) ./"

PRAWNOS_LOCAL_APT_VARS := $(PRAWNOS_LOCAL_APT_REPO) $(PRAWNOS_LOCAL_APT_SOURCE)

### KERNEL UNIVERSAL
PRAWNOS_KERNEL_PACKAGES := $(PRAWNOS_KERNEL)/packages
PRAWNOS_KERNEL_RESOURCES_SHARED := $(PRAWNOS_KERNEL)/resources/shared

### KERNEL TARGETED (paths partially defined by $TARGET)
PRAWNOS_KERNEL_RESOURCES := $(PRAWNOS_KERNEL)/resources/$(TARGET)
PRAWNOS_KERNEL_BUILD := $(PRAWNOS_BUILD)/linux-$(KVER)-$(KERNEL_TYPE)-$(TARGET)
PRAWNOS_KERNEL_BUILT := $(PRAWNOS_KERNEL_BUILD)/vmlinux.kpart
PRAWNOS_KERNEL_PACKAGE_IMAGE := $(PRAWNOS_KERNEL_PACKAGES)/prawnos-linux-image-$(KERNEL_TYPE)-$(TARGET)
PRAWNOS_KERNEL_PACKAGE_HEADERS := $(PRAWNOS_KERNEL_PACKAGES)/prawnos-linux-headers-$(KERNEL_TYPE)-$(TARGET)

#### KERNEL TARGETS FOR RK3588 WITH UBOOT BOOTLOADER
PRAWNOS_BOOTLOADER_BUILD := $(PRAWNOS_BUILD)/bootloader
PRAWNOS_KERNEL_RK3588_BUILT := $(PRAWNOS_KERNEL_BUILD)/arch/arm64/boot/Image
PRAWNOS_KERNEL_DTB_RK3588_FIREFLY_SERVER_BUILT := $(PRAWNOS_KERNEL_BUILD)/arch/arm64/boot/dts/rockchip/rk3588-firefly-itx-3588j.dtb
PRAWNOS_KERNEL_DTB_RK3588_FIREFLY_BUILT := $(PRAWNOS_KERNEL_BUILD)/arch/arm64/boot/dts/rockchip/rk3588-firefly-itx-3588j-dual-mipi101-M101014-BE45-A1.dtb

### BOOTLOADER UNIVERSAL
PRAWNOS_BOOTLOADER_PACKAGES := $(PRAWNOS_BOOTLOADER)/packages
PRAWNOS_BOOTLOADER_RESOURCES_SHARED := $(PRAWNOS_BOOTLOADER)/resources/shared

### BOOTLOADER TARGETED (paths partially defined by $TARGET)
PRAWNOS_BOOTLOADER_RESOURCES := $(PRAWNOS_BOOTLOADER)/resources/$(TARGET)
PRAWNOS_BOOTLOADER_BUILT := $(PRAWNOS_BOOTLOADER_BUILD)/uboot.img
PRAWNOS_BOOTLOADER_UBOOT_PACKAGE_IMAGE := $(PRAWNOS_BOOTLOADER_PACKAGES)/prawnos-uboot-image-$(TARGET)

### INITRAMFS
PRAWNOS_INITRAMFS_IMAGE := $(PRAWNOS_BUILD)/PrawnOS-initramfs.cpio.gz

### ATH9K
PRAWNOS_ATH9K_BUILD := $(PRAWNOS_BUILD_SHARED)/open-ath9k-htc-firmware

### WGET
#keeping the server timestamps confuses make, causing needless rebuilds
WGET_OPTS := --no-use-server-timestamps

#=========================================================================================


#Place all shared make rules below
#=========================================================================================

### Build directory rules, use with "|" to make them "order only" prerequisites

$(PRAWNOS_BUILD_SHARED):
	mkdir -p $(PRAWNOS_BUILD_SHARED)

$(PRAWNOS_BUILD):
	mkdir -p $(PRAWNOS_BUILD)

$(PRAWNOS_BUILD_LOGS): | $(PRAWNOS_BUILD)
	mkdir -p $(PRAWNOS_BUILD_LOGS)

$(PRAWNOS_BUILD_SOURCES): | $(PRAWNOS_BUILD)
	mkdir -p $(PRAWNOS_BUILD_SOURCES)

$(PRAWNOS_BUILD_DEBOOTSTRAP_APT_CACHE): | $(PRAWNOS_BUILD)
	mkdir -p $(PRAWNOS_BUILD_DEBOOTSTRAP_APT_CACHE)

$(PRAWNOS_BUILD_CHROOT_APT_CACHE): | $(PRAWNOS_BUILD)
	mkdir -p $(PRAWNOS_BUILD_CHROOT_APT_CACHE)

$(PRAWNOS_LOCAL_APT_REPO): | $(PRAWNOS_BUILD)
	mkdir -p $(PRAWNOS_LOCAL_APT_REPO)

#=========================================================================================

#Place all shared make functions below
#=========================================================================================


#=========================================================================================

endif # BUILD_COMMON_MK
