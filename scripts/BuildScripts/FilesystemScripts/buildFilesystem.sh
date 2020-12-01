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
if [ -z "$4" ]
then
    echo "No prawnos_root path supplied"
    exit 1
fi
if [ -z "$5" ]
then
    echo "No shared scripts path supplied"
    exit 1
fi
if [ -z "$6" ]
then
    echo "No Filesystem resources path supplied"
    exit 1
fi
if [ -z "$7" ]
then
    echo "No TARGET arch supplied"
    exit 1
fi
if [ -z "$8" ]
then
    echo "No Prawnos build directory supplied"
    exit 1
fi

KVER=$1
DEBIAN_SUITE=$2
BASE=$3
PRAWNOS_ROOT=$4
PRAWNOS_SHARED_SCRIPTS=$5
PRAWNOS_FILESYSTEM_RESOURCES=$6
TARGET_ARCH=$7
PRAWNOS_BUILD=$8

outmnt=$(mktemp -d -p "$(pwd)")

outdev=$(losetup -f)

install_resources=$PRAWNOS_FILESYSTEM_RESOURCES/InstallResources
build_resources=$PRAWNOS_FILESYSTEM_RESOURCES
build_resources_apt=$build_resources/apt

# Import the package lists, shared scripts
source $PRAWNOS_SHARED_SCRIPTS/*

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

# Retry a command up to 5 times, else fail
retry_until() {
    #must clear and unclear the "e" flag to avoid trapping into cleanup before retrying
    set +e
    command=("$@")

    NUM_RETRIES=0
    MAX_RETRIES=5

    until [ "$NUM_RETRIES" -eq 5 ] || ${command[@]}; do
        echo Apt failure, NUM_RETRIES = $NUM_RETRIES, trying again in 5 seconds
        ((NUM_RETRIES++))
        sleep 5
    done
    if [ "$NUM_RETRIES" -ge "$MAX_RETRIES" ]; then
        exit 1
    fi
    set -e
}

# Download, cache externally, and optionally install the specified packages
# also implements retries since the build dockers seem to fail randomly
# 2: mount of the chroot
# 3: list of packages in install
# 4: if true, download, cache, and install. If false just download and cache
apt_install() {
  PRAWNOS_BUILD=$1
  shift
  outmnt=$1
  shift
  install=$1
  shift
  package_list=("$@")

  retry_until chroot $outmnt apt install -y -d ${package_list[@]}

  cp "$outmnt/var/cache/apt/archives/"* "$PRAWNOS_BUILD/chroot-apt-cache/" || true
  if [ "$install" = true ]; then
      retry_until chroot $outmnt apt install -y ${package_list[@]}
  fi
}

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

# create a 2.5GB image with the Chrome OS partition layout
# Bumped to keep both Gnome and Xfce
#TODO: change back to 40 (2GB)
create_image $BASE $outdev 50M 60 $outmnt

# use default debootstrap mirror if none is specified
if [ "$PRAWNOS_DEBOOTSTRAP_MIRROR" = "" ]
then
    PRAWNOS_DEBOOTSTRAP_MIRROR=http://ftp.us.debian.org/debian
fi

# install Debian on it
export DEBIAN_FRONTEND=noninteractive
# need ca-certs, gnupg, openssl to handle https apt links and key adding for deb.prawnos.com
printf -v debootstrap_debs_install_joined '%s,' "${debootstrap_debs_install[@]}"
qemu-debootstrap --arch $TARGET_ARCH $DEBIAN_SUITE \
                 --include ${debootstrap_debs_install_joined%,} \
                 --keyring=$build_resources_apt/debian-archive-keyring.gpg \
                 $outmnt \
                 $PRAWNOS_DEBOOTSTRAP_MIRROR \
                 --cache-dir=$PRAWNOS_BUILD/debootstrap-apt-cache/

chroot $outmnt passwd -d root

#Place the config files and installer script and give them the proper permissions
echo -n PrawnOS > $outmnt/etc/hostname
cp -R $install_resources/ $outmnt/InstallResources/
# and the icons for the lockscreen and app menu
mkdir $outmnt/InstallResources/icons/
cp $build_resources/logo/icons/icon-small.png $outmnt/InstallResources/icons/
cp $build_resources/logo/icons/ascii/* $outmnt/InstallResources/icons/
cp scripts/InstallScripts/* $outmnt/InstallResources/
cp $PRAWNOS_SHARED_SCRIPTS/package_lists.sh $outmnt/InstallResources/
cp scripts/InstallScripts/InstallPrawnOS.sh $outmnt/
chmod +x $outmnt/*.sh

#Setup the chroot for apt
#This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
cp /etc/hosts $outmnt/etc/
cp $build_resources_apt/sources.list $outmnt/etc/apt/sources.list
cp $build_resources_apt/prawnos.list $outmnt/etc/apt/sources.list.d/
sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list
sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list.d/prawnos.list
if [ "$DEBIAN_SUITE" != "sid" ]
then
    # Install sid (unstable) as an additional source for bleeding edge packages.
    cp $build_resources_apt/sid.list $outmnt/etc/apt/sources.list.d/
    #setup apt pinning
    cp $build_resources_apt/sid.pref $outmnt/etc/apt/preferences.d/
fi
if [ "$DEBIAN_SUITE" = "buster" ]
then
    # sid and bullseye don't have backports or security; it's present for all other suites
    cat $build_resources_apt/updates.list >> $outmnt/etc/apt/sources.list
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list
    cp $build_resources_apt/backports.list $outmnt/etc/apt/sources.list.d/
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/sources.list.d/backports.list
    cp $build_resources_apt/backports.pref $outmnt/etc/apt/preferences.d/
    sed -i -e "s/suite/$DEBIAN_SUITE/g" $outmnt/etc/apt/preferences.d/backports.pref
    # Install bullseye (testing) as an additional source
    cp $build_resources_apt/bullseye.list $outmnt/etc/apt/sources.list.d/
    cp $build_resources_apt/bullseye.pref $outmnt/etc/apt/preferences.d/
fi

#Bring in the deb.prawnos.com gpg keyring
cp $build_resources_apt/deb.prawnos.com.gpg.key $outmnt/InstallResources/
chroot $outmnt apt-key add /InstallResources/deb.prawnos.com.gpg.key
chroot $outmnt apt update

#Setup the locale
cp $build_resources/locale.gen $outmnt/etc/locale.gen
chroot $outmnt locale-gen

#Copy in the apt cache
cp "$PRAWNOS_BUILD/chroot-apt-cache/"* "$outmnt/var/cache/apt/archives/" || true

echo IMAGE SIZE
df -h

#Make apt retry on download failure
chroot $outmnt echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

#Install the base packages
chroot $outmnt apt update
apt_install $PRAWNOS_BUILD $outmnt true ${base_debs_install[@]}

#add the live-boot fstab
cp -f $build_resources/external_fstab $outmnt/etc/fstab
chmod 644 $outmnt/etc/fstab

#Cleanup to reduce install size
chroot $outmnt apt-get autoremove --purge
chroot $outmnt apt-get clean

#Download the shared packages to be installed by InstallPackages.sh:
apt_install $PRAWNOS_BUILD $outmnt false ${base_debs_download[@]}

#DEs
#Download the xfce packages to be installed by InstallPackages.sh:
apt_install $PRAWNOS_BUILD $outmnt false ${xfce_debs_download[@]}

#Download the gnome packages to be installed by InstallPackages.sh:
apt_install $PRAWNOS_BUILD $outmnt false ${gnome_debs_download[@]}


# we want to include all of our built packages in the apt cache for installation later, but we want to let apt download dependencies
# if required
# this gets tricky when we build some of the dependencies. To avoid issues
# first, manually cache the deb
# apt install ./local-package.deb alone doesn't work because apt will resort to downloading it from deb.prawnos.com, which we dont want
# copy into /var/cache/apt/archives to place it in the cache
#next call apt install -d on the ./filename or on the package name and apt will recognize it already has the package cached, so will only cache the dependencies

#Copy the built prawnos debs over to the image, and update apts cache
cd $PRAWNOS_ROOT && make filesystem_packages_install  TARGET=$TARGET_ARCH INSTALL_TARGET=$outmnt/var/cache/apt/archives/
chroot $outmnt apt install -y ${prawnos_base_debs_prebuilt_install[@]}
chroot $outmnt apt install -y -d ${prawnos_base_debs_prebuilt_download[@]}
chroot $outmnt apt install -y -d ${prawnos_xfce_debs_prebuilt_download[@]}
if [ $TARGET_ARCH = "armhf" ]
then
    chroot $outmnt apt install -y -d ${prawnos_armhf_debs_prebuilt_download[@]}
fi

if [ $TARGET_ARCH = "arm64" ]
then
    chroot $outmnt apt install -y -d ${prawnos_arm64_debs_prebuilt_download[@]}
fi

## PrawnOS mesa packages
# PrawnOS only has specific mesa packages when the debian upstream versions are too old.
# commented out until we need it again

# chroot $outmnt apt install -y -d ${prawnos_mesa_prebuilt_install[@]}

#Setup console font size
cp -f $build_resources/console-font.sh $outmnt/etc/profile.d/console-font.sh

#Cleanup hosts
rm -rf $outmnt/etc/hosts #This is what https://wiki.debian.org/EmDebian/CrossDebootstrap suggests
echo -n "127.0.0.1        PrawnOS" > $outmnt/etc/hosts

#Cleanup apt retry
chroot $outmnt rm -f /etc/apt/apt.conf.d/80-retries

# do a non-error cleanup
umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT
