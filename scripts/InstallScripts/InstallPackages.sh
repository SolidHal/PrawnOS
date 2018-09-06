#!/bin/sh -xe

DIR=/InstallResources

locale-gen
#Install lxqt, wicd
apt install -y xorg acpi-support lightdm tasksel dpkg librsvg2-common xorg xserver-xorg-input-libinput alsa-utils anacron avahi-daemon eject iw libnss-mdns xdg-utils lxqt wicd-daemon wicd wicd-curses wicd-gtk xserver-xorg-input-synaptics
#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf $DIR/default.pa /etc/pulse/default.pa
cp -rf $DIR/sound.sh /etc/acpi/sound.sh
cp -rf $DIR/headphone-acpi-toggle /etc/acpi/events/headphone-acpi-toggle
mkdir /etc/X11/xorg.conf.d/
cp -rf $DIR/50-synaptics.conf /etc/X11/xorg.conf.d/


echo " Enter new username: "
read username
adduser $username
usermod -a -G sudo,netdev $username


reboot
