#!/bin/bash

# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2020 Austin English <austinenglish@gmail.com>
# Copyright (c) 2020 Hal Emmerich <hal@halemmerich.com>

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
TEST_TARGET="$2"
TEST_KERNEL_TYPE="$3"
RELEASE_VERSION="$4"

IMG="PrawnOS-${RELEASE_VERSION}-${TEST_TARGET}-${TEST_KERNEL_TYPE}"
IMAGE="${IMG}.img"
IMAGE_GIT="${IMG}-git-${GITHUB_SHA}.img"

cd "$(dirname "$0")/.."

# Get dependencies
apt-get update

## even farther future TODO: break into tests for each package, step in build process

#required basic dependencies for build system
apt install -y make git

git config --global --add safe.directory $(pwd)

make install_dependencies_yes TARGET=$TEST_TARGET KERNEL_TYPE=$TEST_KERNEL_TYPE

# Note: there's an error for /proc/modules, but at least building the image works fine:
# libkmod: ERROR ../libkmod/libkmod-module.c:1657 kmod_module_new_from_loaded: could not open /proc/modules: No such file or directory
make image TARGET=$TEST_TARGET KERNEL_TYPE=$TEST_KERNEL_TYPE

# rename the image to include git sha:
mv $IMAGE $IMAGE_GIT

# compress, otherwise downloads take forever
xz -1 $IMAGE_GIT
