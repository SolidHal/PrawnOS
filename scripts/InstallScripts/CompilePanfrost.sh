#!/bin/bash

sudo apt -y build-dep mesa
sudo apt -y install mesa-utils
cd /tmp
git clone https://gitlab.freedesktop.org/mesa/mesa -b master
cd mesa
mkdir build
cd build
meson .. . -Ddri-drivers= -Dvulkan-drivers= -Dgallium-drivers=panfrost,kmsro -Dlibunwind=false
sudo ninja install

sudo apt -y remove llvm-7-dev
sudo apt -y autoremove



sudo reboot
