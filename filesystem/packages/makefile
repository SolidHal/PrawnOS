PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk

SUBDIRS = $(shell ls -d */)

all:
	for dir in $(SUBDIRS) ; do \
		make -C  $$dir ; \
	done


clean:
	for dir in $(SUBDIRS) ; do \
		make clean -C  $$dir ; \
	done

install:
	$(info filesystem install target is $(INSTALL_TARGET))
	for dir in $(SUBDIRS) ; do \
		make install INSTALL_TARGET=$(INSTALL_TARGET) -C  $$dir ; \
	done

#this allows a makefile or script to specifically build one filesystem package
.PHONY: build_package
build_package:
ifndef BUILD_PACKAGE
	$(error BUILD_PACKAGE is not set)
endif
	make -C $(BUILD_PACKAGE)
