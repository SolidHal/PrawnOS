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
	$(info packages install target is $(INSTALL_TARGET))
	for dir in $(SUBDIRS) ; do \
		make install INSTALL_TARGET=$(INSTALL_TARGET) -C  $$dir  ; \
	done
