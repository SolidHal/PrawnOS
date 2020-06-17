#!/bin/bash

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

# ======================================== Package Lists =========================================
# ================================ KEEP THESE LISTS ALPHABETIZED! ================================

base_debs_install=(
    alsa-utils
    apt-utils
    bash-completion
    busybox-static
    bzip2
    ca-certificates
    cgpt
    cryptsetup
    e2fsprogs-l10n
    gdisk
    git
    ifupdown
    inetutils-ping
    iproute2
    isc-dhcp-client
    iw
    kmod
    kpartx
    laptop-detect
    less
    libatm1
    libgpg-error-l10n
    libnss-systemd
    libpam-cap nftables
    nano
    net-tools
    netcat-openbsd
    parted
    psmisc
    rsync
    traceroute
    udev
    uuid-runtime
    vim
    wpasupplicant
    xz-utils
)

base_debs_download=(
    acpi-support
    alsa-utils
    anacron
    avahi-daemon
    bluetooth
    chromium
    crda
    dbus-user-session
    dpkg
    dtrx
    eject
    emacs
    firefox-esr
    iw
    libnss-mdns
    librsvg2-common
    libutempter0
    lightdm
    mousepad
    sudo
    sysfsutils
    tasksel
    vlc
    xdg-utils
    xorg
    xorg
    xserver-xorg-input-libinput
)

mesa_debs_download=(
    libegl-mesa0
    libegl1-mesa
    libgl1-mesa-dri
    libglapi-mesa
    libglu1-mesa
    libglx-mesa0
)

xfce_debs_download=(
    accountsservice
    dbus-user-session
    dconf-cli
    dconf-editor
    network-manager-gnome
    network-manager-openvpn
    network-manager-openvpn-gnome
    numix-gtk-theme
    papirus-icon-theme
    plank
    system-config-printer
    tango-icon-theme
    xfce4
    xfce4-goodies
    xfce4-power-manager
    xfce4-terminal
)

lxqt_debs_download=(
    lightdm
    lxqt
    network-manager-gnome
    network-manager-openvpn
    network-manager-openvpn-gnome
    pavucontrol-qt
)

gnome_debs_download=(
    dbus-user-session
    dconf-cli
    dconf-editor
    eog
    epiphany-browser
    evince
    file-roller
    fonts-cantarell
    gdm3
    gedit
    gir1.2-peas-1.0
    gnome-clocks
    gnome-disk-utility
    gnome-logs
    gnome-session
    gnome-shell-extensions
    gnome-software
    gnome-software-plugin-flatpak
    gnome-system-monitor
    gnome-terminal
    gnome-tweaks
    libgtk3-perl
    libpeas-1.0-0
    lightdm
    lxqt
    materia-gtk-theme
    nautilus
    nautilus-admin
    network-manager-gnome
    network-manager-gnome
    network-manager-openvpn
    network-manager-openvpn
    network-manager-openvpn-gnome
    network-manager-openvpn-gnome
    pavucontrol-qt
    seahorse
)

prawnos_debs_prebuilt_download=(
    font-source-code-pro
    xsecurelock
)

prawnos_debs_prebuilt_install=(
    flashmap
)

# ====================================== END Package Lists =======================================
