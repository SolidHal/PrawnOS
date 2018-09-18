#!/bin/bash -xe

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
apt install -y xorg acpi-support lightdm tasksel dpkg librsvg2-common xorg xserver-xorg-input-libinput alsa-utils anacron avahi-daemon eject iw libnss-mdns xdg-utils xserver-xorg-input-synaptics mousepad vlc dconf-tools
apt install -y wicd-daemon wicd wicd-curses wicd-gtk

[ "$DE" = "xfce" ] && apt install -y xfce4 dbus-user-session system-config-printer tango-icon-theme xfce4-power-manager xfce4-terminal xfce4-goodies numix-gtk-theme plank
[ "$DE" = "lxqt" ] && apt install -y lxqt

#Install packages not in an apt repo
[ "$DE" = "xfce" ] && dpkg -i $DIR/xfce-themes/*
#Copy in xfce4 default settings
[ "$DE" = "xfce" ] && cp -f $DIR/xfce-config/xfce-perchannel-xml/* /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
[ "$DE" = "xfce" ] && cp -f $DIR/xfce-config/panel/* /etc/xdg/xfce4/panel/
#Copy in lightdm/light greeter settings
[ "$DE" = "xfce" ] && cp -f $DIR/xfce-config/lightdm/* /etc/lightdm/
#Copy in wallpapers
[ "$DE" = "xfce" ] && rm /usr/share/images/desktop-base/default && cp $DIR/wallpapers/* /usr/share/images/desktop-base/

#Make plank autostart
[ "$DE" = "xfce" ] && cp $DIR/xfce-config/plank/plank.desktop /etc/xdg/autostart/


#Copy in acpi, pulse audio, trackpad settings, funtion key settings
cp -rf $DIR/default.pa /etc/pulse/default.pa
cp -rf $DIR/sound.sh /etc/acpi/sound.sh
cp -rf $DIR/headphone-acpi-toggle /etc/acpi/events/headphone-acpi-toggle
mkdir /etc/X11/xorg.conf.d/
cp -rf $DIR/50-synaptics.conf /etc/X11/xorg.conf.d/

apt clean && apt autoremove --purge

echo " Enter new username: "
read username
adduser $username
usermod -a -G sudo,netdev $username


#install plank launchers
#[ "$DE" = "xfce" ] && mkdir -p /home/$username/.config/plank/dock1/launchers/
#[ "$DE" = "xfce" ] && cp $DIR/xfce-config/plank/plank-launchers/* /home/$username/.config/plank/dock1/launchers/



reboot
