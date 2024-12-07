#!/bin/bash

set -e

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


### SHARED CONST AND VARS
RESOURCES=/etc/prawnos/install/resources
SCRIPTS=/etc/prawnos/install/scripts

# TODO: when these scripts are packaged, place these in a shared script instead of in every file that needs them
device_veyron_speedy="Google Speedy"
device_veyron_minnie="Google Minnie"
device_veyron_mickey="Google Mickey"
device_gru_kevin="Google Kevin"
device_gru_bob="Google Bob"

get_device() {
    local device=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
    echo $device
}

### END SHARED CONST AND VARS


# Import the package lists
source $SCRIPTS/package_lists.sh


set_time() {
    echo "-----Enter the date in format 'YYYY-MM-DD':-----"
    read -r udate
    echo "-----Enter the time in format 'hh:mm:ss':-----"
    read -r utime
    # cant use timedatectl here since we are targeting the chroot
    until $CHROOT_PREFIX hwclock --set --date "$udate $utime"
    do
        echo "-----Enter the date in format 'YYYY-MM-DD':-----"
        read -r udate
        echo "-----Enter the time in format 'hh:mm:ss':-----"
        read -r utime
    done

    echo "set the time and date to $udate $utime"
}

clean_up_local_apt_repo() {
    echo "removing the local apt repo"
    sed -e '/prawnos-local-apt-repo/ s/^#*/#/' -i /etc/apt/sources.list
    rm -rf $RESOURCES/prawnos-local-apt-repo
}


cat $RESOURCES/ascii-icon.txt
echo ""

# while true; do
#     read -r -p "Install (X)fce4, or (G)nome, if unsure choose (X)fce: " XL
#     case $XL in
#         [Gg]* ) DE=gnome; break;;
#         [Xx]* ) DE=xfce; break;;
#         * ) echo "Please answer (X)fce4, (G)nome";;
#     esac
# done
DE=gnome

#Set the timezone and time
dpkg-reconfigure tzdata
set_time

## GENERAL CONFIG
#Install shared packages
DEBIAN_FRONTEND=noninteractive apt install -y ${base_debs_download[@]}
#TODO fix the prebuilts for bookworm
# DEBIAN_FRONTEND=noninteractive apt install -y ${prawnos_base_debs_prebuilt_download[@]}

# DEBIAN_FRONTEND=noninteractive apt install -y prawnos-general-config

## DEVICE SPECIFIC CONFIG
#Copy in acpi, pulse audio, trackpad settings, funtion key settings
device_model=$(get_device)

#TODO fix the prebuilts for bookworm
# if [[ $device_model == $device_veyron_speedy ]] || [[ $device_model == $device_veyron_minnie ]]
# then
#     DEBIAN_FRONTEND=noninteractive apt install -y prawnos-veyron-config
# fi

# if [[ $device_model == $device_gru_kevin ]] || [[ $device_model == $device_gru_bob ]]
# then
#     DEBIAN_FRONTEND=noninteractive apt install -y prawnos-gru-config
# fi

if [[ $(uname -m) == "aarch64" ]]
then
    # we only build tor for aarch64 aka arm64, sorry armhf
    DEBIAN_FRONTEND=noninteractive apt install -y tor-browser
fi

# remove some packages that we don't actually want.
#TODO: determine what packages recommends are bringing these in
apt remove -y gnome-software

## DE SPECIFIC
if [ "$DE" = "gnome" ]
then

  apt install -y ${gnome_debs_download[@]}
  apt install -y ${prawnos_gnome_debs_prebuilt_download[@]}

  #TODO: debug why rotation is flipped
  # work around issue #234
  apt remove -y iio-sensor-proxy


fi


clean_up_local_apt_repo

apt clean -y && apt autoremove --purge -y

#reload the CA certificate symlinks
update-ca-certificates --fresh

#enable periodic TRIM
cp /lib/systemd/system/fstrim.{service,timer} /etc/systemd/system
systemctl enable fstrim.timer

