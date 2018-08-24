#!/bin/sh -xe

# Build fs, image


KVER=4.17.2

#Ensure Sudo
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

outmnt=$(mktemp -d -p `pwd`)
inmnt=$(mktemp -d -p `pwd`)

outdev=/dev/loop4
indev=/dev/loop5

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is sometimes required to properly clean the loop devices and ensure a clean build 
cleanup() {
  set +e

  umount -l $inmnt > /dev/null 2>&1
  rmdir $inmnt > /dev/null 2>&1
  losetup -d $indev > /dev/null 2>&1

  umount -l $outmnt > /dev/null 2>&1
  rmdir $outmnt > /dev/null 2>&1
  losetup -d $outdev > /dev/null 2>&1

  set +e

  umount -l $inmnt > /dev/null 2>&1
  rmdir $inmnt > /dev/null 2>&1
  losetup -d $indev > /dev/null 2>&1

  umount -l $outmnt > /dev/null 2>&1
  rmdir $outmnt > /dev/null 2>&1
  losetup -d $outdev > /dev/null 2>&1
}

trap cleanup INT TERM EXIT


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
create_image librean-stretch-c201-libre-2GB.img $outdev 50M 40 $outmnt

# install Debian on it
export LC_ALL="en_US.UTF-8" #Change this as necessary if not US
export DEBIAN_FRONTEND=noninteractive
qemu-debootstrap --arch armhf stretch --include locales,init $outmnt http://deb.debian.org/debian
chroot $outmnt passwd -d root

#Place the config files and installer script and give them the proper permissions
echo -n librean > $outmnt/etc/hostname
cp -R os_configs/ $outmnt/os_configs/
cp Install.sh $outmnt/Install.sh
chmod +x $outmnt/os_configs/sound.sh
chmod +x $outmnt/Install.sh

#install -D -m 644 80disable-recommends $outmnt/etc/apt/apt.conf.d/80disable-recommends #This should fix the issue of crda being installed but unconfigured causing regulatory.db firmware loading errors in dmesg

#Setup the chroot for apt 
#This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
cp /etc/hosts $outmnt/etc/
cp sources.list $outmount/etc/apt/sources.list

#Setup the locale
cp /etc/locale.gen $outmnt/etc/

#Install the base packages
chroot $outmnt apt update
chroot $outmnt apt install -y initscripts udev kmod net-tools inetutils-ping traceroute iproute2 isc-dhcp-client wpasupplicant iw alsa-utils cgpt vim-tiny less psmisc netcat-openbsd ca-certificates bzip2 xz-utils ifupdown nano apt-utils python python-urwid

#Cleanup to reduce install size
chroot $outmnt apt-get autoremove --purge
chroot $outmnt apt-get clean

#Download the packages to be installed by Install.sh: TODO: potentially dpkg-reconfigure locales?
chroot $outmnt apt-get install -y -d xorg acpi-support lightdm tasksel dpkg librsvg2-common xorg xserver-xorg-input-libinput alsa-utils anacron avahi-daemon eject iw libnss-mdns xdg-utils lxqt wicd-daemon wicd wicd-curses wicd-gtk xserver-xorg-input-synaptics

#Cleanup hosts
rm -rf $outmnt/etc/hosts #This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
echo -n "127.0.0.1        librean" > $outmnt/etc/hosts

# put the kernel in the kernel partition, modules in /lib/modules and AR9271
# firmware in /lib/firmware
dd if=linux-$KVER/vmlinux.kpart of=${outdev}p1 conv=notrunc
make -C linux-$KVER ARCH=arm INSTALL_MOD_PATH=$outmnt modules_install
rm -f $outmnt/lib/modules/3.14.0/{build,source}
install -D -m 644 open-ath9k-htc-firmware/target_firmware/htc_9271.fw $outmnt/lib/firmware/ath9k_htc/htc_9271-1.4.0.fw

# create a 15GB image
create_image librean-stretch-c201-libre-15GB.img $indev 512 30777343 $inmnt

# copy the kernel and / of the 2GB image to the 15GB one
dd if=${outdev}p1 of=${indev}p1 conv=notrunc
cp -a $outmnt/* $inmnt/

#Cleanup the 15GB image
umount -l $inmnt
rmdir $inmnt
losetup -d $indev

# move the 15GB image inside the 2GB one
cp -f librean-stretch-c201-libre-15GB.img $outmnt/
echo "DONE!"
cleanup

