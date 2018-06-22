# debsus

A build system for making blobless debian and mainline kernel for the Asus c201 Chromebook


Build a mainline kernel and Debian filesystem with:
No blobs, anywhere. 
Support for Aetheros AR271 usb wifi dongles through the open source firmware
Minimal toolset intended as a based, including tools to setup a wifi connection
Sources from only main, not contrib or non-free which keeps Debian libre
TODO: basic graphical desktop like xfce

### why

Combined with libreboot,an AR271 wifi dongle, and a libre OS (like Debian, the one built by this) the asus c201 is a fully libre machine with no blobs, or microcode.

### Dependencies

Debsus has been tested on Debian Stretch (in a vm)
These packages are required:

```
	apt install --no-install-recommends --no-install-suggests \
		parted cgpt \
		git gawk device-tree-compiler vboot-kernel-utils gcc-arm-none-eabi \
	    u-boot-tools \
		gcc make libc-dev wget g++ cmake \
		binfmt-support qemu-user-static debootstrap \
		lzip libssl-dev
```

### Building
Currently split between 'buildKernel.sh' and 'buildDebianFs.sh'
Run the kernel one then the fs one. 

### GPU Support

Watch this link for gpu support:
https://gitlab.freedesktop.org/panfrost

### Build the wifi dongle into the laptop

Check out my instructions here: https://github.com/SolidHal/AsusC201-usb-wifi-from-webcam

### Credits and Legal Information

Thanks to dimkr for his great devsus scripts, which debsus is based on
https://github.com/dimkr/devsus

Because of this started as a fork of devsus, much of this repos history can be found at https://github.com/SolidHal/devsus/tree/hybrid_debian

Debsus is free and unencumbered software released under the terms of the GNU
General Public License, version 2; see COPYING for the license text. For a list
of its authors and contributors, see AUTHORS.
