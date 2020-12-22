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
    libinput-tools
    libnss-systemd
    libpam-cap nftables
    lshw
    nano
    net-tools
    netcat-openbsd
    network-manager
    parted
    pciutils
    psmisc
    rsync
    traceroute
    udev
    usbutils
    uuid-runtime
    vim
    vboot-utils
    xdotool
    xz-utils
)

# packages installed for GUI installs (gnome/lxqt/xfce):
# FIXME: blueman can be moved to xfce only once gnome-bluetooth in settings works properly
shared_desktop_debs_download=(
    acpi-support
    alsa-utils
    anacron
    avahi-daemon
    blueman
    bluetooth
    crda
    dbus-user-session
    dpkg
    dkms
    eject
    firefox-esr
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
    sudo
    sysfsutils
    tasksel
    vlc
    xdg-utils
    xorg
    xserver-xorg-input-libinput
)

xfce_debs_download=(
    accountsservice
    dbus-user-session
    dconf-cli
    dconf-editor
    lightdm
    mousepad
    network-manager-gnome
    network-manager-openvpn
    network-manager-openvpn-gnome
    numix-gtk-theme
    papirus-icon-theme
    plank
    system-config-printer
    xfce4
    xfce4-goodies
    xfce4-power-manager
    xfce4-terminal
)

lxqt_debs_download=(
    lightdm
    lxqt
    mousepad
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
# and choosing xfce
prawnos_xfce_debs_prebuilt_download=(
    xsecurelock
    prawnos-xfce-config
    libinput-gestures
)

# packages built by prawnos, to be installed when running InstallPrawnOS
# and choosing gnome
prawnos_gnome_debs_prebuilt_download=(
    prawnos-gnome-config
)

# packages built by prawnos, to be installed when running InstallPrawnOS
prawnos_base_debs_prebuilt_download=(
    prawnos-general-config
    lagrange-gemini-browser
)

# packages built by prawnos, to be installed at build time
prawnos_base_debs_prebuilt_install=(
    font-source-code-pro
    flashmap
    mosys
)

# these are only required when the debian mesa version is too old for us
prawnos_mesa_prebuilt_install=(
    libgbm1=20.2.1-100
    libgl1-mesa-dri=20.2.1-100
    libegl1-mesa=20.2.1-100
    libegl-mesa0=20.2.1-100
    libglapi-mesa=20.2.1-100
    libgl1-mesa-glx=20.2.1-100
    libgles2-mesa=20.2.1-100
    libglx-mesa0=20.2.1-100
    libosmesa6=20.2.1-100
    libwayland-egl1-mesa=20.2.1-100
    mesa-opencl-icd=20.2.1-100
    mesa-va-drivers=20.2.1-100
    mesa-vdpau-drivers=20.2.1-100
    mesa-vulkan-drivers=20.2.1-100
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
