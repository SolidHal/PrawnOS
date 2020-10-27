# PrawnOS Documentation

Some additional documentation for PrawnOS that wouldn't fit in the README

## Useful XFCE4 keybindings and libinput-gestures:
### Gestures:
#### Config file: /etc/libinput-gestures.conf
* four finger swipe left:    Switch to left workspace
* four finger swipe right:   Switch to right workspace

### Keybindings

#### Configure under Settings->Window Manager->Keyboard
* control+alt+left:           move window to left workspace
* control+alt+right:          move window to right workspace

* alt+left:               tile widow to the left
* alt+right:              tile window to the right
* alt+up:                 maximize window

* alt+tab:                    app switcher

#### Configure under Settings->Keyboard->Application Shortcuts
* alt+space :                 App launcher (spotlight-esque)
* control+alt+l:              Lock screen
* Brightness scripts are also called here and can be remapped here or in ~/.Xmodmap

#### Configured using xkb
* "search" key:               function (fn) key

* fn + backspace:             delete
* fn + up:                    page up
* fn + down:                  page down
* fn + left:                  home
* fn + right:                 end

* fn + "brightness up key":         increase backlight
* fn + "brightness down key":       decrease backlight
* fn + "volume mute":               mute volume
* fn + "volume down":               decrease volume
* fn + "volume up":                 increase volume

## Initramfs and Encryption
PrawnOS uses a custom initramfs, custom init script, and dmcrypt/LUKS to enable full root partition encryption

Because the c201s bootloader, depthcharge, can't be given dynamic cmdline parameters like grub we can't use the "usual" method of setting up an initramfs. Essentially, we can't boot from an initramfs image stored on a /boot partiton

Either the initramfs needs to be built into the part of the kernel image passed to depthcharge using a kernel.its similar to this one by @ifbizo:
```
/dts-v1/;

/ {
	description = "Linux-libre kernel image with one or more FDT blobs";
	#address-cells = <1>;
	images {
		kernel {
			description = "vmlinuz";
			data = /incbin/("/boot/vmlinuz-SED_KVER");
			type = "kernel_noload";
			arch = "arm";
			os = "linux";
			compression = "none";
			load = <0>;
			entry = <0>;
			hash {
				algo = "sha1";
			};
		};
		fdt {
			description = "dtb";
			data = /incbin/("/boot/rk3288-veyron-speedy.dtb");
			type = "flat_dt";
			arch = "arm";
			compression = "none";
			hash {
				algo = "sha1";
			};
		};
		ramdisk@1{
			description = "initrd.img";
			data = /incbin/("/boot/initrd.img-SED_KVER");
			type = "ramdisk";
			arch = "arm";
			os = "linux";
			compression = "none";
			hash@1{
				algo = "sha1";
			};
		};
	};
	configurations {
		default = "conf";
		conf{
			kernel = "kernel";
			fdt = "fdt";
			ramdisk = "ramdisk@1";
		};
	};
};
```
Or it needs to be built into the kernel using the kernel config parameter `CONFIG_INITRAMFS_SOURCE="PrawnOS-initramfs.cpio.gz"`

For PrawnOS I decided to go with building into the kernel to avoid relying on the bootloader, the bootloader may change but the kernel will always support booting an initramfs image.

The script `buildInitramFs.sh` creates the `PrawnOS-initramfs.cpio.gz` image that is then used by `buildKerenl.sh`, copying all of the tools and libraries the initramfs needs from the built filesystem image.

The initramfs is what runs initialy at boot, and allows us to enter a password and decrypt the root partiton

In a normal system, when dmcrypt/LUKS is setup the initramfs image is modified to enable decrypting of the root partiton

Since we have to have a static initramfs image, and can't change it without recompiling the kernel, we detect whether encryption is in use by checking for the tag `crypto_LUKS` on the root device at boot.


### debugging the init script
A rescue debug shell is entered when the init script encounters a problem, or if a device with the partition label `RESCUESHELL` is present

Label any partition on the system with `RESCUESHELL` to enter the initramfs rescue shell before mount and root_switch.

You can do this with `cgpt add -i 1 -l RESCUESHELL /dev/sda` for example to label the first partiton of a usb drive.

This is the suggested method, as then debugging can be enabled/disabled by plugging in/removing the usb device. 


### PrawnOS APT repo
https://deb.prawnos.com


### Key management
apt repo holds a short life signing private key, and the long life master public key 
the short life signing key is a sub key of the master key
This way we can safely keep the master key off of any distribution servers.
This also allows us to revoke the signing key and issue a new one all without users needing to
update their key store, as the master public key will be valid for all sub keys

importing/exporting was done based off of https://www.debuntu.org/how-to-importexport-gpg-key-pair/

subkey creation instructions found here https://www.digitalocean.com/community/tutorials/how-to-use-reprepro-for-a-secure-package-repository-on-ubuntu-14-04
under the "Generate a Subkey for Package Signing" section

### Uploading packages to deb.prawnos.halemmerich.compression

use dput
user ~/.dput.cf
```
[deb.prawnos.com]
    fqdn = deb.prawnos.com
    method = scp
    login = debian
    incoming = /var/www/repos/apt/debian/incoming
    allow_unsigned_uploads = true
    ssh_config_options = Port=2222
```

upload the package 
```
dput deb.prawnos.com *.changes
```


### MMC and SD mapping
veyron-speedy:
/dev/mmcblk0 : sd
/dev/mmcblk1 : ???
/dev/mmcblk2 : emmc

gru-kevin:
/dev/mmcblk0 : sd
/dev/mmcblk1 : emmc

gru-bob:
/dev/mmcblk0 :
/dev/mmcblk1 : 

### device identification
cat /sys/firmware/devicetree/base/model

veyron-speedy: "Google Speedy"
gru-kevin:     "Google Kevin"


### Enable usb boot
sometimes when the c201 (and likely other machines) completely drain their battery, the usb boot option is lost. We can re-enable it from inside PrawnOS using the following command: 
```
sudo crosystem dev_boot_usb=1
```

### Modify the dev boot screen (make it not beep loudly)
TODO: expand to be more than just some notes
https://web.archive.org/web/20170711043202/https://johnlewis.ie/neutering-the-developer-mode-screen-on-your-chromebook/
https://gist.github.com/stupidpupil/1e88638e5240476ec1f77d4b27747c88#extra-extra---replace-the-boot-screen-image

flashrom for internal flashing can be found in sid repos. On Debian 10 and derivitives the command is :
```
sudo apt install -t bullseye flashrom
```

The following commands can be used to create a backup image named testread1.img and to write back a modified image named modified.img:

```
sudo flashrom -p linux_mtd -r testread1.img 
sudo flashrom -p linux_mtd -w modified.img 
```

### Modifying a factory image with gbb_utility

Using gbb_utility on a factory image can change settings, without even having to use the vendor operating system. As the changes happen to the (normally) read only region of the coreboot image (the gbb block), these changes can persist when the battery dies. 

This means for example, developer mode can be permanently enabled, and persists even when a battery prematurely dies. The user can confidently replace the vendor operating system on the internal emmc device, and continue to boot their kernel (signed with dev keys) successfully.

For reference, the flags that can be set can be found here: https://chromium.googlesource.com/chromiumos/platform/vboot/+/master/_vboot_reference/firmware/include/gbb_header.h

Make sure that flashrom and vboot-utils are installed. This can be on either the host or an external device; the following command works on Debian and derivitives: 
```
sudo apt install flash vboot-utils 
```

On Coreboot/Depthcharge devices (this means no legacy bios or uefi implementations), these three flags will be the ones mosts users will want to set: 
```
#define GBB_FLAG_DEV_SCREEN_SHORT_DELAY	        	0x00000001
#define GBB_FLAG_FORCE_DEV_SWITCH_ON			0x00000008
#define GBB_FLAG_FORCE_DEV_BOOT_USB			0x00000010
```

As these flags add up to 0x00000019, we can drop the preceding zeroes and issue the following command: 
```
gbb_utility --set --flags 0x19 modified.img 
```



### Reading and writing with an external flasher

By using an external flasher (ie, a Raspberry Pi) one can make changes to their factory coreboot image without needing to remove the write-protect screw. 

When the write-protect screw is in place, using flashrom on the device to backup the factory image in NOT recommended. This is because the md5sum of the image will change between power cycles. 

To obtain an accurate backup, opening up the case to gain physical access is required. At this point, the user has the option of either:


1) Removing the write-protect screw. Flashrom can now be used on the host device (chromebook), and md5sums will be consistent accross power cycles. 

OPTIONAL: Once done backingup and writing a modified image, restore the write-protect screw for additional security.

or 

2) Using an external flashing tool, such as the aforementioned Raspberry Pi, attach your chip clipper to the chip. Take care not to fry your chip by plugging the clipper backwards. The following commands may be used to create a backup image named testread1.img and to write back a modified image named modified.img:

```
sudo flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=512 -r testread1.img 
sudo flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=512 -w modified.img 
```

It is recommended to create three test reads, and run 'md5sum testread*.img' to confirm consistency. It is also advised to use your favorite hex editor to scroll through the image, looking for plain english strings. 

### Disabling the Bright White Screen of Maximum Brightness at Boot

The quick and easy way is:

```
touch null-images
gbb_utility --set --bmpfv=null-images modified.img
```

### Extracting the factory bitmaps to a folder named to-repack:

```
gbb_utility --get --bmpfv=factory-bitmaps testread1.img 
bmpblk_utility -x -d to-repack factory-bitmaps 
```

TODO: Document the repacking process. Notes from jcs.org's post on openbsd on chromebook pixel would come in handy.
ALSO TODO: Identify which bitmaps contain trademarked images. This can come in handy for those wishing to debrand their coreboot image, or rebrand their libreboot image. This however is easier said than done, as both the trademarked logo and text are embedded into the bitmap files spread accross 42 different languages.
