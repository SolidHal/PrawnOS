
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
4) test emmc install & boot
5) start looking at uboot
