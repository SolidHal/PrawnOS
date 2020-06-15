#!/bin/bash

set -x
set -e

# Build fs, image


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2018 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.



#Ensure Sudo
if [ ! $UID = "0" ]
then
    echo "Please run this script with sudo, or as root:"
    echo "sudo $0 $*"
    exit 1
fi

if [ -z "$1" ]
then
    echo "No kernel version supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No debian suite supplied"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No base file system image filename supplied"
    exit 1
fi
KVER=$1
DEBIAN_SUITE=$2
BASE=$3

outmnt=$(mktemp -d -p `pwd`)

outdev=/dev/loop5

install_resources=resources/InstallResources
build_resources=resources/BuildResources
script_resources=scripts/
package_lists=$script_resources/package_lists.sh

# Import the package lists
source $package_lists

#HACK XSECURELOCK our usage of stable and unstable packages has caught up to us. We end up carrying conflicting files if
# we grab build-essential from stable and xsecurelock from unstable. This was fixed by grabbing build-essential from
# unstable as well, but that conflicts with some of the gnome packages it seems. Luckily, we can now build xsecurelock
# for buster instead of grabbing it from unstable.
# I'm rethinking the build system to make (heh) this more elegant, but for now to get the build fixed I'll implement this
XSECURELOCK_PATH=packages/filesystem/xsecurelock


#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is sometimes required to properly clean the loop devices and ensure a clean build
cleanup() {
  set +e

  umount -l $outmnt > /dev/null 2>&1
  rmdir $outmnt > /dev/null 2>&1
  losetup -d $outdev > /dev/null 2>&1

  umount -l $outmnt > /dev/null 2>&1
  rmdir $outmnt > /dev/null 2>&1
  losetup -d $outdev > /dev/null 2>&1

  #delete the base file, we didn't complete our work
  rm -rf $BASE
  echo "FILESYSTEM BUILD FAILED"
  exit 1
}

trap cleanup INT TERM EXIT

#layout the partitons and write filesystem information
create_image() {
  dd if=/dev/zero of=$1 bs=$3 count=$4 conv=sparse
  parted --script $1 mklabel gpt
  cgpt create $1
  kernel_start=8192
  kernel_size=65536
  cgpt add -i 1 -t kernel -b $kernel_start -s $kernel_size -l Kernel -S 1 -T 5 -P 10 $1
  #Now the main filesystem
  root_start=$(($kernel_start + $kernel_size))
  end=`cgpt show $1 | grep 'Sec GPT table' | awk '{print $1}'`
  root_size=$(($end - $root_start))
  cgpt add -i 2 -t data -b $root_start -s $root_size -l Root $1
  # $root_size is in 512 byte blocks while ext4 uses a block size of 1024 bytes
  losetup -P $2 $1
  mkfs.ext4 -F -b 1024 ${2}p2 $(($root_size / 2))

  # mount the / partition
  mount -o noatime ${2}p2 $5
}

build_install_crossystem() {
    # install crossystem
    apt install -y vboot-utils

    #install clang and pre-reqs
    apt install -y clang uuid-dev meson pkg-config cmake libcmocka-dev cargo

    flashmap_src=/root/flashmap
    mosys_src=/root/mosys
    mkdir $flashmap_src
    mkdir $mosys_src
    #clone flashmap, need to build libfmap
    git clone https://github.com/dhendrix/flashmap.git /root/flashmap
    cd $flashmap_src && make all
    cd $flashmap_src && make install
    ldconfig

    #clone mosys. Later releases start depending on the minijail library which we would have to build, and that we don't care about anyway on linux
    git clone https://chromium.googlesource.com/chromiumos/platform/mosys /root/mosys
    cd $mosys_src && git checkout release-R69-10895.B

    mkdir $mosys_src/build
    # compile the c parts
    cd $mosys_src && CFLAGS="-Wno-error" CC=clang meson -Darch=arm $mosys_src/build
    cd $mosys_src && ninja -C $mosys_src/build

    # install mosys so crossystem can access it. It EXPECTS it to be right here and fails otherwise...
    mkdir -p /usr/sbin/
    cp --verbose $mosys_src/build/mosys /usr/sbin/

    # cleanup the source
    rm -rf $flashmap_src
    rm -rf $mosys_src

    # cleanup the unnecessary build packages, need the noninteractive flag as -y is not enough to avoid prompting users on remove for some reason
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove clang meson libcmocka-dev cargo cmake pkg-config

}

# create a 2GB image with the Chrome OS partition layout
create_image $BASE $outdev 50M 40 $outmnt

# use default debootstrap mirror if none is specified
if [ "$PRAWNOS_DEBOOTSTRAP_MIRROR" = "" ]
then
    PRAWNOS_DEBOOTSTRAP_MIRROR=http://ftp.us.debian.org/debian
fi

# install Debian on it
export DEBIAN_FRONTEND=noninteractive
# need ca-certs, gnupg, openssl to handle https apt links and key adding for deb.prawnos.com
qemu-debootstrap --arch armhf $DEBIAN_SUITE --include  openssl,ca-certificates,gnupg,locales,init --keyring=$build_resources/debian-archive-keyring.gpg $outmnt $PRAWNOS_DEBOOTSTRAP_MIRROR
chroot $outmnt passwd -d root


#Place the config files and installer script and give them the proper permissions
echo -n PrawnOS > $outmnt/etc/hostname
cp -R $install_resources/ $outmnt/InstallResources/
# and the icons for the lockscreen and app menu
mkdir $outmnt/InstallResources/icons/
cp $build_resources/logo/icons/icon-small.png $outmnt/InstallResources/icons/
cp $build_resources/logo/icons/ascii/* $outmnt/InstallResources/icons/
cp scripts/InstallScripts/* $outmnt/InstallResources/
cp $package_lists $outmnt/InstallResources/
cp scripts/InstallScripts/InstallPrawnOS.sh $outmnt/
chmod +x $outmnt/*.sh

#Setup the chroot for apt
#This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
cp /etc/hosts $outmnt/etc/
cp $build_resources/sources.list $outmnt/etc/apt/sources.list
sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list
if [ "$DEBIAN_SUITE" != "sid" ]
then
    # sid doesn't have updates or security; they're present for all other suites
    cat $build_resources/updates.list >> $outmnt/etc/apt/sources.list
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list
    # sid doesn't have backports; it's present for all other suites
    cp $build_resources/backports.list $outmnt/etc/apt/sources.list.d/
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list.d/backports.list
    #setup apt pinning
    cp $build_resources/backports.pref $outmnt/etc/apt/preferences.d/
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/preferences.d/backports.pref
    # Install sid (unstable) as an additional source for bleeding edge packages.
    cp $build_resources/sid.list $outmnt/etc/apt/sources.list.d/
    #setup apt pinning
    cp $build_resources/sid.pref $outmnt/etc/apt/preferences.d/
fi
if [ "$DEBIAN_SUITE" = "buster" ]
then
    # Install bullseye (testing) as an additional source
    cp $build_resources/bullseye.list $outmnt/etc/apt/sources.list.d/
    #setup apt pinning
    cp $build_resources/bullseye.pref $outmnt/etc/apt/preferences.d/
fi

#Bring in the deb.prawnos.com gpg keyring
cp $build_resources/deb.prawnos.com.gpg.key $outmnt/InstallResources/
chroot $outmnt apt-key add /InstallResources/deb.prawnos.com.gpg.key
chroot $outmnt apt update

#Setup the locale
cp $build_resources/locale.gen $outmnt/etc/locale.gen
chroot $outmnt locale-gen

#Install the base packages
chroot $outmnt apt update
chroot $outmnt apt install -y ${base_debs_install[@]}

#build and install crossystem/mosys, funky way to call the bash function inside the chroot
export -f build_install_crossystem
chroot $outmnt /bin/bash -ec "build_install_crossystem"

#add the live-boot fstab
cp -f $build_resources/external_fstab $outmnt/etc/fstab
chmod 644 $outmnt/etc/fstab

#Cleanup to reduce install size
chroot $outmnt apt-get autoremove --purge
chroot $outmnt apt-get clean

#Download support for libinput-gestures
#Package is copied into /InstallResources/packages
chroot $outmnt apt install -y libinput-tools xdotool build-essential

# we want to include all of our built packages in the apt cache for installation later, but we want to let apt download dependencies
# if required
# this gets tricky when we build some of the dependencies. To avoid issues 
# first, manually cache the deb
# apt install ./local-package.deb alone doesn't work because apt will resort to downloading it from deb.prawnos.com, which we dont want
# copy into /var/cache/apt/archives to place it in the cache
#next call apt install -d on the ./filename or on the package name and apt will recognize it already has the package cached, so will only cache the dependencies
#HACK XSECURELOCK
PRAWN_ROOT=$(pwd)
cd $XSECURELOCK_PATH && make
cd $PRAWN_ROOT
#TODO: replace with cd packages && make install $outmnt/var/cache/apt/archives/
cp $XSECURELOCK_PATH/xsecurelock_*_armhf.deb $outmnt/var/cache/apt/archives/
chroot $outmnt apt install -y -d xsecurelock

#Download the shared packages to be installed by Install.sh:
chroot $outmnt apt-get install -y -d ${base_debs_download[@]}

## DEs
#Download the xfce packages to be installed by Install.sh:
chroot $outmnt apt-get install -y -d ${xfce_debs_download[@]}

#Download the lxqt packages to be installed by Install.sh:
chroot $outmnt apt-get install -y -d ${lxqt_debs_download[@]}

#Download the gnome packages to be installed by Install.sh:
chroot $outmnt apt-get install -y -d ${gnome_debs_download[@]}

## GPU support
#download mesa packages
chroot $outmnt apt-get install -y -d ${mesa_debs_download[@]}

#Cleanup hosts
rm -rf $outmnt/etc/hosts #This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
echo -n "127.0.0.1        PrawnOS" > $outmnt/etc/hosts

# do a non-error cleanup
umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
