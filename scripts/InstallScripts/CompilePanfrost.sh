#!/bin/bash

sudo apt install -y bison cmake flex gettext git libdrm-dev libexpat1-dev libwayland-dev libwayland-egl-backend-dev libx11-dev libx11-xcb-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev libxdamage-dev libxext-dev libxrandr-dev libxshmfence-dev libxxf86vm-dev mesa-utils pkg-config python3-mako python3-pip python3-setuptools wayland-protocols zlib1g-dev
#Uncomment the following if planning to build against master (20.3) and newer
#sudo apt install -y libxcb-shm0-dev
sudo pip3 install meson ninja

cd /tmp || exit 1
git clone https://gitlab.freedesktop.org/mesa/mesa -b 20.2
mkdir -p mesa/build
cd mesa/build || exit 1
meson .. . -Dprefix=/opt -Ddri-drivers= -Dvulkan-drivers= -Dgallium-drivers=panfrost,kmsro -Dlibunwind=false
sudo ninja install

echo "You may now reboot"
