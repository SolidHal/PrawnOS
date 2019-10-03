# PrawnOS Documentation

Some additional documentation for PrawnOS that wouldn't fit in the README

## Useful XFCE4 keybindings and libinput-gestures:
### Gestures:
#### Config file: /etc/libinput-gestures.conf
* four finger swipe left:    Switch to left workspace
* four finger swipe right:   Switch to right worksace

### Keybindings

#### Configure under Settings->Window Manager->Keyboard
* control+alt+left:           move window to left workspace
* control+alt+right:          move window to right workspace

* control+left:               tile widow to the left
* control+right:              tile window to the right
* control+up:                 maximize window

* alt+tab:                    app switcher

#### Configure under Settings->Keyboard->Application Shortcuts
* alt+space :                 App launcher (spotlight-esque)
* control+alt+l:              Lock screen
* Brightness scripts are also called here and can be remapped here or in ~/.Xmodmap

#### Configured using ~/.Xmodmap
* "search" key:                Mode switch aka m_s (function key)

* m_s + backspace:             delete
* m_s + up:                    page up
* m_s + down:                  page down
* m_s + left:                  home
* m_s + right:                 end
* m_s + period:                insert

* "brightness up key":         increase backlight
* "brightness down key":       decrease backlight
* "volume mute":               mute volume
* "volume down":               decrease volume
* "volume up":                 increase volume

* m_s + "brightness up key":   F7
* m_s + "brightness down key": F6
* m_s + "volume mute key":     F8
* m_s + "volume down key":     F9
* m_s + "volume up key":       F10

#### Configured using ~/.xinputrc
* alt+left                     left a word
* alt+right                    right a word

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

Since we have to have a static initramfs image, and can't change it without recompiling the kernel, we have to be a little crafty to support unencrypted and encrypted root partitons with the same initramfs

This is achieved by placing flags in the /boot partition, aka `/dev/mmcblk2p2` or `/dev/sda2`. The /boot partiton is empty on an unencrypted system. When root encryption is set up, the file `root_encryption` is created, which the initramfs init script uses to determine that it should try and decrypt the root partiton 

### debugging the init script
A rescue debug shell is entered when the init script encounters a problem, or if the `debug` flag is set

You can enable the debug flag by mounting /boot and creating a file named `debug`

To make the system boot normally, from the debug prompt, run `rm /boot/debug` and `exit` to reboot



