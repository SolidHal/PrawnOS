.DEFAULT_GOAL := default


KERNEL_IMAGE := prawnos-linux-*-image-armhf
KERNEL_INSTALL_SCRIPT := install-prawnos-kernel.sh

default: $(all)

all:
#nothing special to do to make, as we already have all of the necessary components
	@echo done!

install:
	install --group=root --owner=root -d /boot
	install --group=root --owner=root --mode=644 $(KERNEL_IMAGE) /boot
	install --group=root --owner=root --mode=755 $(KERNEL_INSTALL_SCRIPT) /bin
