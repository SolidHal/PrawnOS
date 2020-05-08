#!/bin/bash

# This file is part of PrawnOS (http://www.prawnos.com)
# Copyright (c) 2020 Austin English <austinenglish@gmail.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.

set -e
set -x

GITHUB_SHA="$1"

cd "$(dirname "$0")/.."

# Get dependencies listed in README.md:
apt-get update
apt-get -y install --no-install-recommends --no-install-suggests bc binfmt-support bison cgpt cmake debootstrap device-tree-compiler flex g++ gawk gcc gcc-arm-none-eabi git libc-dev libncurses-dev libssl-dev lzip make parted patch qemu-user-static texinfo u-boot-tools vboot-kernel-utils wget

# And install stuff that is missing from the Debian/buster container:
apt-get -y install --no-install-recommends --no-install-suggests bzip2 ca-certificates cpio file gpg gpg-agent kmod udev

# Note: there's an error for /proc/modules, but at least building the image works fine:
# libkmod: ERROR ../libkmod/libkmod-module.c:1657 kmod_module_new_from_loaded: could not open /proc/modules: No such file or directory
make image

# rename the image to include git sha:
mv PrawnOS-Shiba-c201.img "PrawnOS-Shiba-c201-git-${GITHUB_SHA}.img"
