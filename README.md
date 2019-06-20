<p align="center">
<img src="/resources/BuildResources/logo/newPrawn_transparent_high_compression.png" alt="PrawnOS" data-canonical-src="/resources/BuildResources/logo/newPrawn_transparent_high_compression.png" width="200" height="200" /></p>

<h1 align="center">
PrawnOS
</h1>


#### A build system for making blobless Debian and mainline kernel for the Asus c201 Chromebook

Build Debian filesystem with:
* No blobs, anywhere. 
* Sources from only main, not contrib or non-free which keeps Debian libre.
* Currently PrawnOS supports xfce and lxqt as choices for desktop enviroment. 

Build a deblobbed mainline kernel with:
* Patches for reliable USB.
* Patches to support the custom GPT partition table required to boot.
* Support for Atheros AR9271 and AR7010 WiFi dongles.
* Support for CSR8150 bluetooth dongles.

Don't want to use one of the two USB ports of for the WiFi dongle? [check out this](#build-the-wifi-dongle-into-the-laptop)

### Why

Combined with Libreboot, an AR9271 or AR7010 WiFi dongle, and a libre OS (like Debian with the main repos, the one built by PrawnOS) the Asus c201 is a fully libre machine with no blobs, or microcode, or Intel Management Engine.

### Image Download

If you don't want to or can't build the image, you can find downloads under <releases> https://github.com/SolidHal/PrawnOS/releases

### Dependencies

Building PrawnOS has been tested on Debian 9 Stretch (in a VM)
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
Clone this Git repo. 

Build the `PrawnOS-...-.img` by running `sudo make image`

This has only been tested on a Debian stretch VM, and borrows some components from the host system to setup apt/debootstrap during the build process so I would recommend using a Debian Stretch VM to avoid any issues. 

### Write to a flash drive or SD card
Write the 2GB image to a flash drive. Make sure to replace $USB_DEVICE with the desired target flash drive or SD card device. If you're not familiar with dd, check out Debian's
 how to page https://www.debian.org/CD/faq/#write-usb
```
sudo dd if=PrawnOs-*-c201-libre-2GB*.img of=/dev/$USB_DEVICE bs=50M; sync
```

### Installing

There are two ways to use PrawnOS. 

The first option is to boot from the external USB or SD device you wrote the image to. 
[click here](#install-to-usb-drive-or-sd-card)
* Booting from an external device allows you to try PrawnOS without removing Chrome OS or whatever Linux you are running on your internal storage (emmc), but it is a much slower experience as the c201 only has USB 2.0. 

The second and, recommended, option is to install it on your internal storage (emmc)
[click here](#install-to-internal-drive-emmc)
* This is faster, and frees up a USB port. 

### Install To USB drive or SD card
Now on the C201, press `control+u` at boot to boot from the USB drive. 

If you are running stock coreboot and haven't flashed Libreboot, you will first have to enable developer mode and enable USB booting. A quick search should get you some good guides, but if you're having issues feel free to open an issue here on github. 


When it boots, login as root. The password is blank. 

#### If you simply want a basic Linux environment with no desktop environment or window manager:
Make sure it's the only storage device plugged in, and run this script to expand the partition and filesystem to the full USB drive. This will reboot when complete, so you'll have to press `control+u` again to boot to the external media. 
```
cd /InstallResources/
./ExpandExternalInstall.sh
```
Congratulations: you are done! Welcome to PrawnOS. You should probably change the root password and make a user, but I'm not your boss or anything so I'll leave that to you. 
If you want a quick guide on how to connect to WiFi, check out [this down below](#connecting-to-wifi-in-a-basic-environment)

#### For everyone else, two scripts need to be run. 

The first expands the partition and filesystem to use the entire drive.
Make sure you only have one USB or SD storage device plugged into the machine.
This will reboot when complete, so you'll have to press `control+u` again to boot to the external media. 
Run:
```
cd /InstallResources/
./ExpandExternalInstall.sh
```
You can verify it worked by running `df -h` after the reboot. The original `/dev/root/` filesystem was only ~2GB
Then run this script which installs either the xfce4 or the lxqt desktop enviroment, sound, trackpad, and Xorg configurations as well as prompts you to make a new user that automatically gets sudo privileges.

If it asks you about terminal encoding and/or locale, just hit enter. The default works for both.  
When finished, it will reboot once again placing you at a login screen. 
```
./InstallPackages.sh
```
This will take a while; USB 2.0 is slow.
Welcome to PrawnOS. If you like it, I would suggest installing it to your internal storage (emmc).


### Install to Internal drive (emmc)
Now on the C201, press `control+u` at boot to boot from the USB drive. 


If you are running stock coreboot and haven't flashed Libreboot, you will first have to enable developer mode and enable USB booting. A quick search should get you some good guides, but if you're having issues feel free to open an issue here on github. 

At the prompt, login as root. The password is blank. 

WARNING! THIS WILL ERASE YOUR INTERNAL EMMC STORAGE (your Chrome OS install or other Linux install and all of the associated user data) Make sure to back up any data you would like to keep before running this.  

If you would like to install it to the internal emmc storage run:
```
cd /
./InstallToInternal.sh
```
_This will show a bunch of scary red warnings that are a result of the emmc (internal storage) being touchy and the kernel message level being set low for debugging. They don't seem to effect anything long-term._

The device will then reboot. If you are running the stock coreboot, you will have to press `control+d` or wait 30 seconds past the beep to boot to the internal storage.

If you are running Libreboot, it should boot to the internal storage by default. If it doesn't, turn off the device and remove the flash drive before turning it on again. 

Now login as root again and run:
```
cd /InstallResources
./InstallPackages.sh
```
Which installs either the xfce4 or the lxqt desktop enviroment, sound, trackpad, and Xorg configurations as well as prompts you to make a new user that automatically gets sudo privileges.


If it asks you about terminal encoding and/or locale, just hit enter. The default works for both.

When finished, it will reboot once again placing you at a login screen. 

Congratulations! Your computer is now a Prawn! https://sprorgnsm.bandcamp.com/track/the-prawn-song

#### Connecting to WiFi in a basic environment
If you just want a basic environment without xfce or lxqt can skip running InstallPackages.sh. You can connect to WiFi using wpa_supplicant by running the following commands:
```
wpa_passphrase <Network_name> <network_password> > wpa.conf
wpa_supplicant -i wlan0 -c wpa.conf
```
Now switch to another tty by pressing ctrl+alt+f2
Login as root, and run
```
dhclient wlan0
```
When that finishes, you should have access to the internet. 


### Documentation
Some useful things can be found in `DOCUMENTATION.md`


### Make options, developer tools
(All of these should be run as root or with sudo to avoid issues) 
The makefile automates many processes that make debugging the kernel or the filesystem easier. 
To begin with:

`make kernel_config` cross compiles `make menuconfig` Cross compiling is required for any of the Linux kernel make options that edit the kernel config, as the Linux kernel build system makes assumptions that change depending on what platform it is targeting. 

`make kernel` builds just the kernel

`make filesystem` builds the -BASE filesystem image with no kernel

`make image` builds the kernel, builds the filesystem if a -BASE image doesn't exist, and combines the two into a new PrawnOS.img using kernel_inject

`make kernel_inject` Injects a newly built kernel into a previously built PrawnOS.img located in the root of the checkout. Usually, this will be a copy of the -BASE image made by make filesystem. Only use this if you already have a built kernel and filesystem -BASE image. 


You can use the environment variable `PRAWNOS_SUITE` to use a Debian suite other than `stretch`.  For example, to use Debian Buster, you can build with `sudo PRAWNOS_SUITE=buster make image`.  Note that only `stretch` and `buster` have been tested.

You can use the environment variable `PRAWNOS_DEBOOTSTRAP_MIRROR` to use a non-default Debian mirror with debootstrap.  For example, to use [Debian's Tor onion service mirror](https://onion.debian.org/) with debootstrap, you can build with `sudo PRAWNOS_DEBOOTSTRAP_MIRROR=http://vwakviie2ienjx6t.onion/debian make image`.


### GPU Support

Watch this link for GPU support:
https://gitlab.freedesktop.org/panfrost
and this one for progress updates:
https://rosenzweig.io/blog/gpu-feed.xml

### Build the WiFi dongle into the laptop

Sick of having a USB dongle on the outside of your machine for wi-fi? Want to be able to use two USB devices at once without a hub? 
Check out the instructions here: https://github.com/SolidHal/AsusC201-usb-wifi-from-webcam
Warning: decent soldering skills required

### Troubleshooting

The pulse audio mixer will only run if you are logged in as a non-root account. This is an issue (feature?) of pulse audio

### Credits and Legal Information

Thanks to dimkr for his great devsus scripts for the Chrome OS 3.14 kernel, from which PrawnOS took much inspiration
https://github.com/dimkr/devsus

Because PrawnOS started as a fork of devsus-3.14, much of this repo's history can be found at https://github.com/SolidHal/devsus/tree/hybrid_debian

PrawnOS is free and unencumbered software released under the terms of the GNU
General Public License, version 2; see COPYING for the license text. For a list
of its authors and contributors, see AUTHORS.



[![Github All Releases](https://img.shields.io/github/downloads/SolidHal/PrawnOS/total.svg)]() [![Built with Spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org)

