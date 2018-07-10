#!/bin/sh -xe

# Build fs, image


KVER=4.17.5

outmnt=$(mktemp -d -p `pwd`)
inmnt=$(mktemp -d -p `pwd`)

outdev=/dev/loop4
indev=/dev/loop5

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is required to properly clean the loop devices and ensure a clean build 
cleanuptwice() {
  cleanup
  cleanup

}

cleanup() {
  set +e

  umount -l $inmnt > /dev/null 2>&1
  rmdir $inmnt > /dev/null 2>&1
  losetup -d $indev > /dev/null 2>&1

  umount -l $outmnt > /dev/null 2>&1
  rmdir $outmnt > /dev/null 2>&1
  losetup -d $outdev > /dev/null 2>&1
}

trap cleanuptwice INT TERM EXIT


create_image() {
  # it's a sparse file - that's how we fit a 16GB image inside a 2GB one
  dd if=/dev/zero of=$1 bs=$3 count=$4 conv=sparse
  parted --script $1 mklabel gpt
  cgpt create $1
  cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 $1
  start=$((8192 + 65536))
  end=`cgpt show $1 | grep 'Sec GPT table' | awk '{print $1}'`
  size=$(($end - $start))
  cgpt add -i 2 -t data -b $start -s $size -l Root $1
  # $size is in 512 byte blocks while ext4 uses a block size of 1024 bytes
  losetup -P $2 $1
  mkfs.ext4 -F -b 1024 -m 0 -O ^has_journal ${2}p2 $(($size / 2))

  # mount the / partition
  mount -o noatime ${2}p2 $5
}

# create a 2GB image with the Chrome OS partition layout
create_image debian-stretch-c201-libre-2GB.img $outdev 50M 40 $outmnt

# INCLUDES=apt-utils,libc6,libdebconfclient0,awk,libz2-1.0,libblzma5,libselinux1,tar,libtinfo5,zlib1g,udev,kmod,net-tools,traceroute,iproute2,isc-dhcp-client,wpasupplicant,iw,alsa-utils,cgpt,vim-tiny,less,psmisc,netcat-openbsd,ca-certificates,bzip2,xz-utils,unscd,lightdm,lightdm-gtk-greeter,xfce4,xorg,ifupdown,nano,wicd,wicd-curses

# install Debian on it
export LC_ALL="en_US.UTF-8" #Change this as necessary if not US
export DEBIAN_FRONTEND=noninteractive
qemu-debootstrap --arch armhf stretch --include locales,init $outmnt http://deb.debian.org/debian
chroot $outmnt passwd -d root
echo -n debsus > $outmnt/etc/hostname
cp -R os_configs/ $outmnt/os_configs/
cp Install.sh $outmnt/Install.sh
ls $outmnt/
chmod +x $outmnt/os_configs/sound.sh
chmod +x $outmnt/Install.sh
#install -D -m 644 80disable-recommends $outmnt/etc/apt/apt.conf.d/80disable-recommends #This should fix the issue of crda being installed but unconfigured causing regulatory.db firmware loading errors in dmesg
#cp -f /etc/resolv.conf $outmnt/etc/
cp /etc/hosts $outmnt/etc/ #This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
cp sources.list $outmount/etc/apt/sources.list
cp /etc/locale.gen $outmnt/etc/
# chroot $outmnt locale-gen
chroot $outmnt apt update
chroot $outmnt apt install -y initscripts udev kmod net-tools inetutils-ping traceroute iproute2 isc-dhcp-client wpasupplicant iw alsa-utils cgpt vim-tiny less psmisc netcat-openbsd ca-certificates bzip2 xz-utils ifupdown nano apt-utils python python-urwid pciutils usbutils
chroot $outmnt apt-get autoremove --purge
chroot $outmnt apt-get clean
chroot $outmnt apt-get install -y -d acpi-support task-xfce-desktop wicd-daemon wicd wicd-curses wicd-gtk xserver-xorg-input-synaptics
#sed -i s/'enable-cache            hosts   no'/'enable-cache            hosts   yes'/ -i $outmnt/etc/nscd.conf
#rm -f $outmnt/etc/resolv.conf
rm -rf $outmnt/etc/hosts #This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests


# put the kernel in the kernel partition, modules in /lib/modules and AR9271
# firmware in /lib/firmware
dd if=linux-$KVER/vmlinux.kpart of=${outdev}p1 conv=notrunc
make -C linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install
rm -f $outmnt/lib/modules/3.14.0/{build,source}
install -D -m 644 open-ath9k-htc-firmware/target_firmware/htc_9271.fw $outmnt/lib/firmware/ath9k_htc/htc_9271-1.4.0.fw

# create a 15GB image
create_image debian-stretch-c201-libre-15GB.img $indev 512 30777343 $inmnt

# copy the kernel and / of the 2GB image to the 15GB one
dd if=${outdev}p1 of=${indev}p1 conv=notrunc
cp -a $outmnt/* $inmnt/

umount -l $inmnt
rmdir $inmnt
losetup -d $indev

# move the 15GB image inside the 2GB one
cp -f debian-stretch-c201-libre-15GB.img $outmnt/
echo "DONE!"
cleanup

