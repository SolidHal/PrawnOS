#!/bin/sh -xe


KVER=4.17.2

outmnt=$(mktemp -d -p `pwd`)
outdev=/dev/loop7

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is required to properly clean the loop devices and ensure a clean build 
cleanuptwice() {
    cleanup
    cleanup

}

cleanup() {
    set +e

    #umount -l $inmnt > /dev/null 2>&1
    #rmdir $inmnt > /dev/null 2>&1
    #losetup -d $indev > /dev/null 2>&1

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1
}

trap cleanuptwice INT TERM EXIT

#Mount the build filesystem image

losetup -P $outdev debian-stretch-c201-libre-2GB*
mount -o noatime ${outdev}p2 $outmnt

# put the kernel in the kernel partition, modules in /lib/modules and AR9271
# firmware in /lib/firmware
dd if=blank_kernel of=${outdev}p1 conv=notrunc
dd if=linux-$KVER/vmlinux.kpart of=${outdev}p1 conv=notrunc
make -C linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install
rm -f $outmnt/lib/modules/3.14.0/{build,source}
install -D -m 644 open-ath9k-htc-firmware/target_firmware/htc_9271.fw $outmnt/lib/firmware/ath9k_htc/htc_9271-1.4.0.fw

echo "DONE!"
cleanup
