PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
include $(PRAWNOS_ROOT)/scripts/common.mk

SUBDIRS = $(shell ls -d */)

all:
	for dir in $(SUBDIRS) ; do \
		make -C  $$dir ; \
	done


clean:
	for dir in $(SUBDIRS) ; do \
		make clean -C  $$dir ; \
	done
