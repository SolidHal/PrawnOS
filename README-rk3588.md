
Now that we can boot into a rootfs, there are many things to do:

### Build system support
- tooling to create server oriented rootfs: DONE
- tooling to create images bootable from sdcard : DONE
- tooling to build uboot upstream
  - build u-boot upstream
  - bring in rk/firefly patches / config
  - investigate the rk bootloader
     - !!! how does the stock system write a new uboot image?
       - look at the partition layout of the mmc
     - can we have A/B uboot images?
- create & bring in patches from the kernel tree : https://github.com/SolidHal/rk3588-kernel-libre
  - right now we are just cloning the patched kernel git repo in kernel/makefile

### Scripting/system support
- Scripting to install to emmc
- network/ssh login
  - configure server: let user specify root password at build time?
- full disk encryption
  - initramfs support
  - hardware key support

### Hardware support
- sata
- pcie
- nvme/m.2
- emmc install & booting
- hdmi (?) not a high priority


TODO:
1) test sata: DONE
2) test pcie: DONE
3) test m.2: DONE
4) test usb: DONE
5) test fan controller: DONE
6) test emmc install & boot
  - mount & write sd card boot part to emmc boot part
  - remove partitions 4-7, create a root fs partition
  - copy the sd root fs to it, like the prawnos installer does
7) start looking at uboot
  - create a package with prawnos partitions, stock uboot that we can restore in maskrom if necessary
TODO: theory: if emmc p1 is not bootable, it might try p2 instead? copy p1 to p2 before testing uboot images


# Fan issues

the cooling-levels of the fan don't seem to be properly changing with the trips/temps
```
cat /sys/class/thermal/cooling_device0/cur_state
```
stays at 0
even when
```
cat /sys/class/thermal/thermal_zone0/temp
```
goes over a temp trip, defined in the dtsi soc_thermal table
