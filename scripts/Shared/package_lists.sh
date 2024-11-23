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


debootstrap_debs_install=(
    apt-transport-https
    build-essential
    ca-certificates
    gnupg
    init
    locales
    openssl
)

base_debs_install=(
    alsa-utils
    apt-utils
    bash-completion
    btrfs-progs
    busybox-static
    bzip2
    ca-certificates
    cryptsetup
    dpkg
    e2fsprogs-l10n
    gdisk
    git
    htop
    ifupdown
    inetutils-ping
    iproute2
    isc-dhcp-client
    iw
    kmod
    kpartx
    kbd
    less
    libatm1
    libgpg-error-l10n
    libnss-systemd
    libpam-cap nftables
    lshw
    nano
    net-tools
    netcat-openbsd
    parted
    pciutils
    psmisc
    ripgrep
    rsync
    sudo
    sysfsutils
    traceroute
    udev
    usbutils
    uuid-runtime
    vim
    xz-utils
)

laptop_base_debs_install=(
    cgpt
    laptop-detect
    libinput-tools
    network-manager
    vboot-utils
)

server_base_debs_install=(
    openssh-server
)

# blueman can be removed once gnome-bluetooth in settings works properly
base_debs_download=(
    acpi-support
    anacron
    avahi-daemon
    bluetooth
    dbus-user-session
    dkms
    eject
    firefox-esr
    gvfs-backends
    gvfs-fuse
    iw
    libegl-mesa0
    libegl1-mesa
    libgl1-mesa-dri
    libglapi-mesa
    libglu1-mesa
    libglx-mesa0
    libnss-mdns
    librsvg2-common
    libutempter0
    libwayland-egl1-mesa
    tasksel
    tor
    vlc
    xdg-utils
    xdotool
    xorg
    xserver-xorg-input-libinput
)


gnome_debs_download=(
    dbus-user-session
    dconf-cli
    dconf-editor
    eog
    evince
    file-roller
    fonts-cantarell
    gdm3
    gedit
    gnome-bluetooth
    gnome-clocks
    gnome-disk-utility
    gnome-logs
    gnome-session
    gnome-shell-extensions
    gnome-system-monitor
    gnome-terminal
    gnome-tweaks
    materia-gtk-theme
    nautilus
    nautilus-admin
    network-manager-gnome
    network-manager-openvpn
    network-manager-openvpn-gnome
    pavucontrol-qt
    seahorse
)

# packages built by prawnos, to be installed when running InstallPrawnOS
# and choosing gnome
prawnos_gnome_debs_prebuilt_download=(
    prawnos-gnome-config
)

# packages built by prawnos, to be installed when running InstallPrawnOS
prawnos_base_debs_prebuilt_download=(
    prawnos-general-config
)

# packages built by prawnos, to be installed at build time
prawnos_base_debs_prebuilt_install=(
    flashmap
    mosys
)

# packages built by prawnos, to be installed when running InstallPrawnOS
# on armhf devices
prawnos_armhf_debs_prebuilt_download=(
    prawnos-veyron-config
)

# packages built by prawnos, to be installed when running InstallPrawnOS
# on arm64 devices
prawnos_arm64_debs_prebuilt_download=(
    prawnos-gru-config
)

# ====================================== END Package Lists =======================================
