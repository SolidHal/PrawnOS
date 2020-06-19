#!/bin/bash -e


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

DIR=/InstallResources
# Import the package lists
source $DIR/package_lists.sh

cat $DIR/icons/ascii-icon.txt
echo ""

while true; do
    read -p "Install (X)fce4, (L)xqt or (G)nome, if unsure choose (X)fce: " XL
    case $XL in
        [Gg]* ) DE=gnome; break;;
        [Xx]* ) DE=xfce; break;;
        [Ll]* ) DE=lxqt; break;;
        * ) echo "Please answer (X)fce4, (L)xqt or (G)nome";;
    esac
done

#Set the timezone
dpkg-reconfigure tzdata

#Install shared packages
DEBIAN_FRONTEND=noninteractive apt install -y ${base_debs_download[@]}
DEBIAN_FRONTEND=noninteractive apt install -y ${mesa_debs_download[@]}
DEBIAN_FRONTEND=noninteractive apt install -y ${prawnos_base_debs_prebuilt_download[@]}

[ "$DE" = "gnome" ] && apt install -y ${gnome_debs_download[@]}
[ "$DE" = "xfce" ] && apt install -y ${xfce_debs_download[@]} ${prawnos_base_debs_prebuilt_install[@]}
[ "$DE" = "lxqt" ] && apt install -y ${lxqt_debs_download[@]}

#install the keymap by patching xkb, then bindings work for any desktop environment
cp $DIR/xkb/compat/* /usr/share/X11/xkb/compat/
cp $DIR/xkb/keycodes/* /usr/share/X11/xkb/keycodes/
cp $DIR/xkb/symbols/* /usr/share/X11/xkb/symbols/

patch /usr/share/X11/xkb/rules/base < $DIR/xkb/rules/base.chromebook.patch
patch /usr/share/X11/xkb/rules/base.lst < $DIR/xkb/rules/base.lst.chromebook.patch
patch /usr/share/X11/xkb/rules/base.xml < $DIR/xkb/rules/base.xml.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev < $DIR/xkb/rules/evdev.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev.lst < $DIR/xkb/rules/evdev.lst.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev.xml < $DIR/xkb/rules/evdev.xml.chromebook.patch

cp  $DIR/xkb/keyboard /etc/default/keyboard

#disable ertm for csr8510 bluetooth, issue #117
echo "module/bluetooth/parameters/disable_ertm = 1" > /etc/sysfs.conf

if [ "$DE" = "gnome" ]
then
  #install firefox-esr default settings
  cp $DIR/firefox-esr/prawn-settings.js /usr/lib/firefox-esr/defaults/pref/
  cp $DIR/firefox-esr/prawn.cfg /usr/lib/firefox-esr/

  #TODO: a config file way to do the following would be nice, so that we can install the configs now instead
  # of having to run the following commands after login
  #Natural scrolling is un-natural
  # gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
  #Tap to click is natural
  # gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
fi

if [ "$DE" = "xfce" ]
then
  # remove light-locker, as it is broken on this machine. See issue https://github.com/SolidHal/PrawnOS/issues/56#issuecomment-504681175
  apt remove -y light-locker
  apt purge -y light-locker

  #Install packages not in an apt repo
  dpkg -i $DIR/xfce-themes/*

  #Copy in xfce4 default settings
  cp -f $DIR/xfce-config/xfce-perchannel-xml/* /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
  cp -f $DIR/xfce-config/panel/* /etc/xdg/xfce4/panel/

  #Copy in lightdm/light greeter settings
  cp -f $DIR/icons/icon-small.png /etc/lightdm/icon.png
  chmod 644 /etc/lightdm/icon.png
  cp -f $DIR/xfce-config/lightdm/* /etc/lightdm/


  #Patch xflock4 to activate xsecurelock
  patch /usr/bin/xflock4 < $DIR/xfce-config/xflock-xsecurelock.patch

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

  #install firefox-esr default settings
  cp $DIR/firefox-esr/prawn-settings.js /usr/lib/firefox-esr/defaults/pref/
  cp $DIR/firefox-esr/prawn.cfg /usr/lib/firefox-esr/

  #Install the source code pro font for spacemacs
  [ -d /usr/share/fonts/opentype ] || mkdir /usr/share/fonts/opentype
  cp -rf $DIR/fonts/* /usr/share/fonts/opentype/
  fc-cache

  #Install inputrc
  cp -rf $DIR/xfce-config/inputrc/.inputrc /etc/skel/

  #Install brightness control scripts
  cp $DIR/xfce-config/brightness/backlight_* /usr/sbin/
fi


#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf $DIR/default.pa /etc/pulse/default.pa
# Disable flat-volumes in pulseaudio, fixes broken sound for some sources in firefox
echo "flat-volumes = no" > /etc/pulse/daemon.conf
cp -rf $DIR/sound.sh /etc/acpi/sound.sh
cp -rf $DIR/headphone-acpi-toggle /etc/acpi/events/headphone-acpi-toggle
mkdir /etc/X11/xorg.conf.d/
cp -rf $DIR/30-touchpad.conf /etc/X11/xorg.conf.d/

apt clean -y && apt autoremove --purge -y

#reload the CA certificate symlinks
update-ca-certificates --fresh

#enable periodic TRIM
cp /lib/systemd/system/fstrim.{service,timer} /etc/systemd/system
systemctl enable fstrim.timer

dmesg -D

echo ""
echo ""
echo ""

cat $DIR/icons/ascii-icon.txt
echo ""
echo "*************Welcome To PrawnOS*************"
echo ""
#Have the user set a root password
echo "-----Enter a password for the root user-----"
until passwd
do
    echo "-----Enter a password for the root user-----"
    passwd
done

#Force a safe username
while true; do
    echo "-----Enter new username:-----"
    read username
    #ensure no whitespace
    case $username in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
done
until adduser $username --gecos ""
do
    while true; do
        echo "-----Enter new username:-----"
        read username
        #ensure no whitespace
        case $username in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
    done
done

usermod -a -G sudo,netdev,input,video,bluetooth $username

dmesg -E

