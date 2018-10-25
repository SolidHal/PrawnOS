#!/bin/bash -xe


# This file is part of PrawnOS (http://www.prawnos.com)
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

DIR=/InstallResources

while true; do
    read -p "install (X)fce4 or (L)xqt, if unsure choose (X)fce4: " XL
    case $XL in
        [Xx]* ) DE=xfce; break;;
        [Ll]* ) DE=lxqt; break;;
        * ) echo "Please answer (X)fce4 or (L)xqt";;
    esac
done

locale-gen
#Install shared packages
apt install -y xorg acpi-support lightdm tasksel dpkg librsvg2-common xorg xserver-xorg-input-libinput alsa-utils anacron avahi-daemon eject iw libnss-mdns xdg-utils mousepad vlc dconf-tools sudo dtrx emacs25
apt install -y network-manager-gnome network-manager-openvpn network-manager-openvpn-gnome

[ "$DE" = "xfce" ] && apt install -y xfce4 dbus-user-session system-config-printer tango-icon-theme xfce4-power-manager xfce4-terminal xfce4-goodies numix-gtk-theme plank
[ "$DE" = "lxqt" ] && apt install -y lxqt

if [ "$DE" = "xfce" ]
then
  #Install packages not in an apt repo
  dpkg -i $DIR/xfce-themes/*

  #Copy in xfce4 default settings
  cp -f $DIR/xfce-config/xfce-perchannel-xml/* /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
  cp -f $DIR/xfce-config/panel/* /etc/xdg/xfce4/panel/
  
  #Copy in lightdm/light greeter settings
  cp -f $DIR/xfce-config/lightdm/* /etc/lightdm/
  
  #Copy in wallpapers
  rm /usr/share/images/desktop-base/default && cp $DIR/wallpapers/* /usr/share/images/desktop-base/

  #Install libinput-gestures and xfdashboard "packages"
  cd $DIR/packages/
  dtrx libinput-gestures.tar.gz
  cd libinput-gestures
  make install
  cd ..

  #Add libinput-gestures config and autostart
  cp $DIR/xfce-config/libinput-gestures/libinput-gestures.conf /etc/
  cp $DIR/xfce-config/libinput-gestures/libinput-gestures.desktop /etc/xdg/autostart/

  #Make plank autostart
  cp $DIR/xfce-config/plank/plank.desktop /etc/xdg/autostart/

  #install plank launcher
  mkdir -p /etc/skel/.config/plank/dock1/launchers/
  cp -rf $DIR/xfce-config/plank/plank-launchers/* /etc/skel/.config/plank/dock1/launchers/

  #Install xmodmap map, autostart
  cp -rf $DIR/xfce-config/xmodmap/.Xmodmap /etc/skel/
  cp -rf $DIR/xfce-config/xmodmap/.xinitrc /etc/skel/

  #Install inputrc
  cp -rf $DIR/xfce-config/inputrc/.inputrc /etc/skel/

  #Install brightness controls
  cp $DIR/xfce-config/brightness/backlight_* /usr/sbin/
  mkdir -p /etc/udev/rules.d/
  cp $DIR/xfce-config/brightness/backlight.rules /etc/udev/rules.d/
fi


#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf $DIR/default.pa /etc/pulse/default.pa
cp -rf $DIR/sound.sh /etc/acpi/sound.sh
cp -rf $DIR/headphone-acpi-toggle /etc/acpi/events/headphone-acpi-toggle
mkdir /etc/X11/xorg.conf.d/
cp -rf $DIR/30-touchpad.conf /etc/X11/xorg.conf.d/

apt clean && apt autoremove --purge

dmesg -D

#Force a safe username
while true; do
    echo " Enter new username: "
    read username
    #ensure no whitespace
    case $username in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
done
until adduser $username --gecos ""
do
    while true; do
        echo " Enter new username: "
        read username
        #ensure no whitespace
        case $username in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
    done
done

usermod -a -G sudo,netdev,input,video $username

dmesg -E



reboot
