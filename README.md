# PrawnOS

A build system for making blobless debian and mainline kernel for the Asus c201 Chromebook


Build a mainline kernel and Debian filesystem with:
No blobs, anywhere. 
Support for Aetheros AR271 usb wifi dongles through the open source firmware
Minimal toolset intended as a based, including tools to setup a wifi connection
Sources from only main, not contrib or non-free which keeps Debian libre
Currently PrawnOS supports lxqt, with plans to include xfce as an option in the future

### why

Combined with libreboot, an AR271 wifi dongle, and a libre OS (like Debian, the one built by this) the asus c201 is a fully libre machine with no blobs, or microcode.

### Dependencies

Building PrawnOS has been tested on Debian 9 Stretch (in a vm)
These packages are required:

```
	apt install --no-install-recommends --no-install-suggests \
		parted cgpt \
		git gawk device-tree-compiler vboot-kernel-utils gcc-arm-none-eabi \
	        u-boot-tools \
		gcc make libc-dev wget g++ cmake \
		binfmt-support qemu-user-static debootstrap \
		lzip libssl-dev libncurses-dev flex bison sudo patch
```

### Build
Currently split between 'buildKernel.sh' and 'buildDebianFs.sh'
Run the kernel one then the fs one.

### Install
Write the 2GB image to a flash drive, which contains the full 15GB (acutally 14.7GB) to write to the internal storage. We can do this since the 15GB image is a sparse file. 
```
sudo dd if=PrawnOs-Alpha-c201-libre-2GB.img of=/dev/$USB_DEVICE bs=50M
```

Now on the C201, login as root. The password is blank. 
Write the 15GB image to the internal storage
For me this was /dev/mmcblk2 but it may be /dev/mmcblk1 for you depending on what device it assigns to sdcards

WIP

Reboot. Run /Install.sh which will install lxqt, wicd, and some device configurations. This will reboot one last time when done.
```
/Install.sh
```
You should now be greeted by a login screen. 

If you just want a basic enviroment without xfce upu can skip running Install.sh but I recommend installing wicd-curses for wifi configuration. 

### GPU Support

Watch this link for gpu support:
https://gitlab.freedesktop.org/panfrost
and this one for progress updates:
https://rosenzweig.io/blog/gpu-feed.xml

### Build the wifi dongle into the laptop

Check out the instructions here: https://github.com/SolidHal/AsusC201-usb-wifi-from-webcam


### Troubleshooting

The pulse audio mixer will only run if you are logged in as a non-root account. This is an issue (feature?) of pulse audio

### Credits and Legal Information

Thanks to dimkr for his great devsus scripts, from which PrawnOS took much inspiration
https://github.com/dimkr/devsus

Because of this started as a fork of devsus, much of this repos history can be found at https://github.com/SolidHal/devsus/tree/hybrid_debian

PrawnOS is free and unencumbered software released under the terms of the GNU
General Public License, version 2; see COPYING for the license text. For a list
of its authors and contributors, see AUTHORS.
