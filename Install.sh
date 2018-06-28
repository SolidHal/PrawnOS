#!/bin/sh -xe

#Setup locales
apt install -y locales
#Install xfce, wicd
apt install -y task-xfce-desktop wicd wicd-curses wicd-gtk xserver-xorg-input-synaptics
#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf /os_configs/default.pa /etc/pulse/default.pa
mkdir /etc/acpi
cp -rf /os_configs/default.sh /etc/acpi/default.sh
mkdir /etc/X11/xorg.conf.d/
cp -rf /os_configs/50-synaptics.conf /etc/X11/xorg.conf.d/

reboot
