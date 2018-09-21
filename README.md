# PrawnOS

A build system for making blobless debian and mainline kernel for the Asus c201 Chromebook


Build a mainline kernel and Debian filesystem with:
No blobs, anywhere. 
Support for Aetheros AR271 usb wifi dongles through the open source firmware
Minimal toolset intended as a based, including tools to setup a wifi connection
Sources from only main, not contrib or non-free which keeps Debian libre
Currently PrawnOS supports lxqt, with plans to include xfce as an option in the future

### why

Combined with libreboot, an AR271 wifi dongle, and a libre OS (like Debian with the main repos, the one built by this) the asus c201 is a fully libre machine with no blobs, or microcode.

### Image Download

If you don't want to or can't build the image, a download will be made available before next week 

### Dependencies

Building PrawnOS has been tested on Debian 9 Stretch (in a vm)
This is the only build enviroment that is supported. 
These packages are required:

```
	apt install --no-install-recommends --no-install-suggests \
		parted cgpt \
		git gawk device-tree-compiler vboot-kernel-utils gcc-arm-none-eabi \
	        u-boot-tools \
		gcc make libc-dev wget g++ cmake \
		binfmt-support qemu-user-static debootstrap \
		lzip libssl-dev libncurses-dev flex bison sudo patch bc
```

### Build
Clone this git repo. 

Build the `PrawnOS-...-.img` by running `sudo make image`

This has only been tested on a Debian stretch VM, and borrows some components from the host system to setup apt/debootstrap during the build process so I would recommend using a Debian Stretch VM to avoid any issues. 

### Install
Write the 2GB image to a flash drive. Make sure to replace $USB_DEVICE with the desired target flash drive
```
sudo dd if=PrawnOs-*-c201-libre-2GB.img of=/dev/$USB_DEVICE bs=50M
```
Now on the C201, login as root. The password is blank. 
If you would like to install it to the internal emmc storage run:
WARNING! THIS WILL ERASE YOUR INTERNAL EMMC STORAGE (your chrome OS install or other linux install and all of the associated user data) MAke sure to back up any data you would like to keep before running this.  
```
cd /
./InstallToInternal.sh
```
**This will show a bunch of scary red warnings that are a result of the emmc (internal storage) being touchy. They don't seem to effect anything longterm.

The device will then reboot, and should boot to the internal storage by default. If it doesn't, turn off the device and remove the flash drive before turning it on again. 

Now login as root again and run:
```
cd /InstallResources
./InstallPackages.sh
```
Which installs the either the xfce4 or the lxqt desktop enviroment, sound, trackpad, and Xorg configurations as well as prompts you to make a new user that automatically gets sudo priviledges.

When finished, it will reboot once again placing you at a login screen. 

If you just want a basic enviroment without xfce or lxqt can skip running InstallPackages.sh. You can connect to wifi using wpa_supplicant by running the following commands:
```
wpa_passphrase <Network_name> <network_password> > wpa.conf
wpa_supplicant -D wext -i wlan0 -c wpa.conf
```
Now switch to another tty by pressing ctrl+alt+f2
Login as root, and run
```
dhclient
```
When that finishes, you should have access to the internet. 

Congratulations! Your computer is now a Prawn! https://sprorgnsm.bandcamp.com/track/the-prawn-song

### Make options, developer tools
(ALl of these should be ran as root or with sudo to avoid issues) 
The makefile automates many processes that make debuggung the kernel or the filesystem easier. 
TO begin with:

`make kernel_config` cross compiles `make menuconfig` Cross compiling is required for any of the linux kernel make options that edit the kernel config, as the linux kernel build system makes assumptions that change depending on what platform it is targeting. 

`make kernel` builds just the kernel

`make filesystem` builds the filesystem and kernel into a PrawnOS.img

`make kernel_inject` Injects a newly built kernel into a previously build PrawnOS.img located in the root of the checkout


### GPU Support

Watch this link for gpu support:
https://gitlab.freedesktop.org/panfrost
and this one for progress updates:
https://rosenzweig.io/blog/gpu-feed.xml

### Build the wifi dongle into the laptop

Sick of having a wsb dongle on the outside of your machine for wi-fi? Want to be able to use two usb devices at once without a hub? 
Check out the instructions here: https://github.com/SolidHal/AsusC201-usb-wifi-from-webcam
Waringing: decent soldering skills required

### Troubleshooting

The pulse audio mixer will only run if you are logged in as a non-root account. This is an issue (feature?) of pulse audio

### Credits and Legal Information

Thanks to dimkr for his great devsus scripts, from which PrawnOS took much inspiration
https://github.com/dimkr/devsus

Because of this started as a fork of devsus, much of this repos history can be found at https://github.com/SolidHal/devsus/tree/hybrid_debian

PrawnOS is free and unencumbered software released under the terms of the GNU
General Public License, version 2; see COPYING for the license text. For a list
of its authors and contributors, see AUTHORS.

