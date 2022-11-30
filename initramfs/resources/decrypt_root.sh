#!/bin/sh

# CRYPTO_ROOTFS is set in /root/.profile by init when using ssh
# or exported by init when this script is ran over serial console

echo "Opening encrypted root partition ${CRYPTO_ROOTFS}, this will take 30s..."
cryptsetup --tries 5 luksOpen ${CRYPTO_ROOTFS} luksroot

dmesg -n 7
mount /dev/mapper/luksroot /newroot

# /dev/pts may not be mounted
umount /dev/pts || true
umount /sys
umount /proc

#switch to the new rootfs
exec switch_root /newroot /sbin/init
