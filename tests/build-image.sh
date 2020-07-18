#!/bin/bash

# This file is part of PrawnOS (https://www.prawnos.com)
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

# Get dependencies
apt-get update

# Note: this is a copy/paste from README.md, if you add anything here, also update it!
# Please make note of the "-y" that is not in the readme command. Not keeping it will break CI :)
apt install --no-install-recommends --no-install-suggests \
    -y \
    bc binfmt-support bison build-essential bzip2 ca-certificates cgpt cmake cpio debhelper \
    debootstrap device-tree-compiler devscripts file flex g++ gawk gcc gcc-arm-none-eabi git gpg \
    gpg-agent kmod libc-dev libncurses-dev libssl-dev lzip make parted patch \
    pbuilder qemu-user-static sudo texinfo u-boot-tools udev vboot-kernel-utils wget


# Note: there's an error for /proc/modules, but at least building the image works fine:
# libkmod: ERROR ../libkmod/libkmod-module.c:1657 kmod_module_new_from_loaded: could not open /proc/modules: No such file or directory
make image

# rename the image to include git sha:
mv PrawnOS-Shiba-c201.img "PrawnOS-Shiba-$TARGET-git-${GITHUB_SHA}.img"
