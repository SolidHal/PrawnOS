ifndef COMMON_MK
COMMON_MK := 1

#Place all shared make vars below
#=========================================================================================
PRAWNOS_BUILD := $(PRAWNOS_ROOT)/build
PRAWNOS_LOCAL_APT_REPO := $(PRAWNOS_BUILD)/prawnos-local-apt-repo
PRAWNOS_LOCAL_APT_SOURCE := "deb [trusted=yes] file://$(PRAWNOS_LOCAL_APT_REPO) ./"

PRAWNOS_SCRIPTS := $(PRAWNOS_ROOT)/scripts
PRAWNOS_PACKAGE_SCRIPTS := $(PRAWNOS_SCRIPTS)/PackageScripts
PRAWNOS_PACKAGE_SCRIPTS_INSTALL_PACKAGE := $(PRAWNOS_SCRIPTS)/PackageScripts/installPackage.sh
PRAWNOS_PACKAGE_SCRIPTS_PBUILD_PACKAGE := $(PRAWNOS_SCRIPTS)/PackageScripts/pbuildPackage.sh
PRAWNOS_PACKAGE_SCRIPTS_UPLOAD_PACKAGE := $(PRAWNOS_SCRIPTS)/PackageScripts/uploadPackage.sh

PBUILDER_DIR := $(PRAWNOS_ROOT)/resources/BuildResources/pbuilder
PBUILDER_CHROOT := $(PRAWNOS_BUILD)/prawnos-pbuilder-armhf-base.tgz
PBUILDER_RC := $(PBUILDER_DIR)/prawnos-pbuilder.rc
PBUILDER_HOOKS := $(PBUILDER_DIR)/hooks

PBUILDER_VARS := $(PBUILDER_CHROOT) $(PBUILDER_RC) $(PBUILDER_HOOKS)
PRAWNOS_LOCAL_APT_VARS := $(PRAWNOS_LOCAL_APT_REPO) $(PRAWNOS_LOCAL_APT_SOURCE)
# Otherwise errors are ignored when output is piped to tee:
SHELL := /bin/bash -o pipefail

#=========================================================================================
endif # COMMON_MK
