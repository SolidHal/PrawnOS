
rk3588 server kernel stalls on boot :/

kernel mainlining support here is interesting https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/commits/rk3588

for now just use the provided kernel image/dtb to get unblocked? 

```
  sudo ./build.sh roc-rk3588s-pc-BE45-A1-ubuntu.mk
  sudo ./build.sh extboot
```

converted config from =m to =y and get the following error:
```
  CHK     include/generated/compile.h
  LD      vmlinux.o
/home/solidhal/ITX-3588J-Linux-SDK/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-ld: drivers/net/wireless/rockchip_wlan/rtl8821cu/core/crypto/aes-internal-enc.o: in function `aes_encrypt':
/home/solidhal/ITX-3588J-Linux-SDK/kernel/drivers/net/wireless/rockchip_wlan/rtl8821cu/core/crypto/aes-internal-enc.c:110: multiple definition of `aes_encrypt'; lib/crypto/aes.o:/home/solidhal/ITX-3588J-Linux-SDK/kernel/lib/crypto/aes.c:373: first defined here
/home/solidhal/ITX-3588J-Linux-SDK/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-ld: drivers/mmc/core/mmc_blk_data(hmac_sha2.o): in function `hmac_sha256':
(.text+0x3240): multiple definition of `hmac_sha256'; drivers/net/wireless/rockchip_wlan/rtl8821cu/core/crypto/sha256.o:/home/solidhal/ITX-3588J-Linux-SDK/kernel/drivers/net/wireless/rockchip_wlan/rtl8821cu/core/crypto/sha256.c:88: first defined here
make[1]: *** [Makefile:1284: vmlinux] Error 1
make: *** [arch/arm64/Makefile:214: roc-rk3588s-pc-mipi101-M101014-BE45-A1.img] Error 2
ERROR: Running build_extboot failed!
ERROR: exit code 2 from line 777:
```

also, looks like a bunch of things are still =m, so maybe fix that too?


TODO:
1) test video
2) test ethernet
3) test m.2
4) test usb
5) test fan controller
6) test emmc install & boot
7) test m.2 install & boot
