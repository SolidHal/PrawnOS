#!/bin/bash -e


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

cat $DIR/icons/ascii-icon.txt
echo ""

while true; do
    read -p "Install (M)inimal or (L)ite, if unsure choose (L)ite: " XL
    case $XL in
        [Mm]* ) DE=mini; break;;
        [Ll]* ) DE=lite; break;;
        * ) echo "Please answer (M)inimal or (L)ite";;
    esac
done

#Set the timezone
dpkg-reconfigure tzdata

#Install shared packages
DEBIAN_FRONTEND=noninteractive apt install -y xorg acpi-support gdm3 tasksel dpkg librsvg2-common xorg xserver-xorg-input-libinput alsa-utils anacron avahi-daemon eject iw libnss-mdns xdg-utils dconf-cli dconf-editor sudo dtrx
DEBIAN_FRONTEND=noninteractive apt install -y network-manager-gnome network-manager-openvpn network-manager-openvpn-gnome gnome-session dbus-user-session accountsservice gnome-js-common gnome-shell-extensions fonts-cantarell

# #skip installing firefox from buster (if buster repos are present, i.e. installed suite is less than bullseye), otherwise from default suite
#DEBIAN_FRONTEND=noninteractive apt -t buster install -y firefox-esr || DEBIAN_FRONTEND=noninteractive apt install -y firefox-esr

# #install generic browser from buster (if buster repos are present, i.e. installed suite is less than bullseye), otherwise from default suite
DEBIAN_FRONTEND=noninteractive apt -t buster install -y epiphany-browser || DEBIAN_FRONTEND=noninteractive apt install -y epiphany-browser

[ "$DE" = "mini" ] && apt install -y gnome-terminal nautilus nautilus-admin
[ "$DE" = "lite" ] && apt install -y gnome-terminal nautilus nautilus-admin gnome-software gnome-software-plugin-flatpak synaptic gedit gnome-system-monitor gnome-clocks evince gnome-disk-utility gnome-shell-extension-appindicator gnome-shell-extension-dashtodock gnome-shell-extension-desktop-icons gnome-shell-extension-workspaces-to-dock

if [ "$DE" = "mini" ]
then
  #Install packages not in an apt repo
#  dpkg -i $DIR/xfce-themes/*

  #Copy in xfce4 default settings
#  cp -f $DIR/xfce-config/xfce-perchannel-xml/* /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
#  cp -f $DIR/xfce-config/panel/* /etc/xdg/xfce4/panel/

  #Copy in lightdm/light greeter settings
#  cp -f $DIR/icons/icon-small.png /etc/lightdm/icon.png
#  chmod 644 /etc/lightdm/icon.png
#  cp -f $DIR/xfce-config/lightdm/* /etc/lightdm/

  #Copy in wallpapers
#  rm /usr/share/images/desktop-base/default && cp $DIR/wallpapers/* /usr/share/images/desktop-base/

  #Install libinput-gestures and xfdashboard "packages"
#  cd $DIR/packages/
#  dtrx libinput-gestures.tar.gz
#  cd libinput-gestures
#  make install
#  cd ..

  #Add libinput-gestures config and autostart
#  cp $DIR/xfce-config/libinput-gestures/libinput-gestures.conf /etc/
#  cp $DIR/xfce-config/libinput-gestures/libinput-gestures.desktop /etc/xdg/autostart/

  #Make plank autostart
#  cp $DIR/xfce-config/plank/plank.desktop /etc/xdg/autostart/

  #install plank launcher
#  mkdir -p /etc/skel/.config/plank/dock1/launchers/
#  cp -rf $DIR/xfce-config/plank/plank-launchers/* /etc/skel/.config/plank/dock1/launchers/

  #install firefox-esr default settings
#  cp $DIR/firefox-esr/prawn-settings.js /usr/lib/firefox-esr/defaults/pref/
#  cp $DIR/firefox-esr/prawn.cfg /usr/lib/firefox-esr/

#  #Install the source code pro font for spacemacs
#  [ -d /usr/share/fonts/opentype ] || mkdir /usr/share/fonts/opentype
#  cp -rf $DIR/fonts/* /usr/share/fonts/opentype/
#  fc-cache

  #Install xmodmap map, autostart
#  cp -rf $DIR/xfce-config/xmodmap/.Xmodmap /etc/skel/
#  cp -rf $DIR/xfce-config/xmodmap/.xinitrc /etc/skel/

  #Install inputrc
#  cp -rf $DIR/xfce-config/inputrc/.inputrc /etc/skel/

  #Install brightness controls
#  cp $DIR/xfce-config/brightness/backlight_* /usr/sbin/
#  mkdir -p /etc/udev/rules.d/
#  cp $DIR/xfce-config/brightness/backlight.rules /etc/udev/rules.d/

# Since we commented out that whole section we have to run a command to avoid an incorrect syntax error
 ls
fi


#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf $DIR/default.pa /etc/pulse/default.pa
cp -rf $DIR/sound.sh /etc/acpi/sound.sh
cp -rf $DIR/headphone-acpi-toggle /etc/acpi/events/headphone-acpi-toggle
mkdir /etc/X11/xorg.conf.d/
cp -rf $DIR/30-touchpad.conf /etc/X11/xorg.conf.d/

# remove light-locker, as it is broken on this machine. See issue https://github.com/SolidHal/PrawnOS/issues/56#issuecomment-504681175
apt remove -y light-locker

# remove xterm, as no one explicitly installed it
apt remove -y xterm

apt clean && apt autoremove --purge

#enable periodic TRIM
cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system || cp /lib/systemd/system/fstrim.{service,timer} /etc/systemd/system
systemctl enable fstrim.timer

dmesg -D

echo ""
echo ""
echo ""

cat $DIR/icons/ascii-icon.txt
echo ""
echo "*************Welcome To PrawnOS*************"
echo ""
#Skip having the user set a root password, since they'll have sudo
#echo "-----Enter a password for the root user-----"
#until passwd
#do
#    echo "-----Enter a password for the root user-----"
#    passwd
#done

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

usermod -a -G sudo,netdev,input,video $username

dmesg -E



reboot
