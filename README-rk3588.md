
Now that we can boot into a rootfs, there are many things to do:

### Build system support
- tooling to create images bootable from sdcard
  - need to add the uboot config, kernel image, dtb, and initrd to the boot partition
- tooling to build uboot upstream
- tooling to create server oriented rootfs: done
- create & bring in patches from the kernel tree : https://github.com/SolidHal/rk3588-kernel-libre

### Hardware support
- sata
- pcie
- nvme/m.2
- emmc install & booting
- hdmi (?) not a high priority


### Software features
- network/ssh login
  - install openssh-server
  - configure server: let user specify root password at build time?
- full disk encryption
