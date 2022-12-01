#!/bin/sh

# CRYPTO_ROOTFS is set in /root/.profile by init when using ssh
# or exported by init when this script is ran over serial console

echo "Available devices:"
blkid

echo "================================================================================"

echo "Opening encrypted root partition ${CRYPTO_ROOTFS}, this will take 30s..."
cryptsetup --tries 5 luksOpen ${CRYPTO_ROOTFS} luksroot

echo "This shell should die momentarily..."

