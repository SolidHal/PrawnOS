#!/bin/bash

sudo apt -y install git libx11-dev meson pkg-config python3-setuptools python3-mako zlib1g-dev libexpat1-dev libdrm-dev bison flex libwayland-dev wayland-protocols libwayland-egl-backend-dev libxext-dev libxdamage-dev libx11-xcb-dev libxcb-glx0-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev libxshmfence-dev libxxf86vm-dev libxrandr-dev gettext
sudo apt -y install mesa-utils

cd /tmp
git clone https://gitlab.freedesktop.org/mesa/mesa -b master
cd mesa
git checkout 6c4b97011b209fb9c034208b2b2f7e261feaf17c
mkdir build
cd build
meson .. . -Dprefix=/usr -Ddri-drivers= -Dvulkan-drivers= -Dgallium-drivers=panfrost,kmsro,swrast -Dlibunwind=false
sudo ninja install

echo "You may now reboot"
