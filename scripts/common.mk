ifndef COMMON_MK
COMMON_MK := 1

#Place all shared make vars below
#=========================================================================================
PBUILDER_CHROOT := $(PRAWNOS_ROOT)/build/prawnos-pbuilder-armhf-base.tgz
PBUILDER_RC := $(PRAWNOS_ROOT)/resources/BuildResources/pbuilder/prawnos-pbuilder.rc
# Otherwise errors are ignored when output is piped to tee:
SHELL := /bin/bash -o pipefail
#=========================================================================================
endif # COMMON_MK
