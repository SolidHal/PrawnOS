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

cat $RESOURCES/ascii-icon.txt
echo ""

while true; do
    read -r -p "Install (X)fce4, or (G)nome, if unsure choose (X)fce: " XL
    case $XL in
        [Gg]* ) DE=gnome; break;;
        [Xx]* ) DE=xfce; break;;
        * ) echo "Please answer (X)fce4, (G)nome";;
    esac
done

#Set the timezone
dpkg-reconfigure tzdata

## GENERAL CONFIG
#Install shared packages
DEBIAN_FRONTEND=noninteractive apt install -y ${shared_desktop_debs_download[@]}
DEBIAN_FRONTEND=noninteractive apt install -y ${prawnos_base_debs_prebuilt_download[@]}

DEBIAN_FRONTEND=noninteractive apt install -y prawnos-general-config

## DEVICE SPECIFIC CONFIG
#Copy in acpi, pulse audio, trackpad settings, funtion key settings
device_model=$(get_device)

if [[ $device_model == $device_veyron_speedy ]] || [[ $device_model == $device_veyron_minnie ]]
then
    DEBIAN_FRONTEND=noninteractive apt install -y prawnos-veyron-config
fi

if [[ $device_model == $device_gru_kevin ]] || [[ $device_model == $device_gru_bob ]]
then
    DEBIAN_FRONTEND=noninteractive apt install -y prawnos-gru-config
fi


# remove some packages that we don't actually want.
#TODO: determine what packages recommends are bringing these in
apt remove -y gnome-software lilyterm

## DE SPECIFIC
if [ "$DE" = "gnome" ]
then

  apt install -y ${gnome_debs_download[@]}
  apt install -y ${prawnos_gnome_debs_prebuilt_download[@]}

  #TODO: debug why rotation is flipped
  # work around issue #234
  apt remove -y iio-sensor-proxy


fi

if [ "$DE" = "xfce" ]
then
  apt install -y ${xfce_debs_download[@]}
  apt install -y ${prawnos_xfce_debs_prebuilt_download[@]}

  # remove light-locker, as it is broken on this machine. See issue https://github.com/SolidHal/PrawnOS/issues/56#issuecomment-504681175
  apt remove -y light-locker
  apt purge -y light-locker

  #Install packages not in an apt repo
  # TODO: likely drop this in favor of just using the upstream
  # dpkg -i $DIR/xfce-themes/*
fi

apt clean -y && apt autoremove --purge -y

#reload the CA certificate symlinks
update-ca-certificates --fresh

#enable periodic TRIM
cp /lib/systemd/system/fstrim.{service,timer} /etc/systemd/system
systemctl enable fstrim.timer

