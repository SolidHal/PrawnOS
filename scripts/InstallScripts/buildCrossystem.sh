#!/bin/sh -xe

#Build mosys, which is required for crossystem


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


# install crossystem
sudo apt install -y vboot-utils

#install clang and pre-reqs
sudo apt install -y clang uuid-dev meson pkg-config cmake libcmocka-dev cargo

#clone flashmap, need to build libfmap
git clone https://github.com/dhendrix/flashmap.git
cd flashmap
make all
sudo make install

#clone mosys. Later releases start depending on the minijail library which we would have to build, and that we don't care about anyway on linux
git clone https://chromium.googlesource.com/chromiumos/platform/mosys
cd mosys
git checkout release-R69-10895.B

# compile the c parts
CC=clang meson -Darch=arm build
ninja -C build
# compile the rust parts
MESON_BUILD_ROOT=build cargo build

# install mosys so crossystem can access it. It EXPECTS it to be right here and fails otherwise...
sudo cp build/mosys /usr/sbin/mosys


# Example crossystem commands, all require root priviledges
#Kernels signature verification:

# crossystem dev_boot_signed_only=1 # enable
# crossystem dev_boot_signed_only=0 # disable

#External media boot:

# crossystem dev_boot_usb=1 # enable
# crossystem dev_boot_usb=0 # disable

#Legacy payload boot:

# crossystem dev_boot_legacy=1 # enable
# crossystem dev_boot_legacy=0 # disable

#Default boot medium:

# crossystem dev_default_boot=disk # internal storage
# crossystem dev_default_boot=usb # external media
# crossystem dev_default_boot=legacy # legacy payload
