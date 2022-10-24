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
RELEASE_VERSION="$3"
BUILD_TYPE="$4"

IMG="PrawnOS-${RELEASE_VERSION}-${TEST_TARGET}"
IMAGE="${IMG}.img"
IMAGE_GIT="${IMG}-git-${GITHUB_SHA}.img"

cd "$(dirname "$0")/.."

# Get dependencies:
apt-get update

# Currently, only kernel/blobby_kernel/image are supported. The prereqs may change if other targets are added:

# Required basic dependencies for build system:
apt install -y make git
make install_dependencies_yes TARGET=$TEST_TARGET

## Build stuff:
    case "$BUILD_TYPE" in
            ## Note: there's an error for /proc/modules, but at least building the kernel/image works fine:
            ## libkmod: ERROR ../libkmod/libkmod-module.c:1657 kmod_module_new_from_loaded: could not open /proc/modules: No such file or directory
        blobby_kernel)
             make blobby_kernel TARGET=$TEST_TARGET
             # FIXME: do we want to make it available via github actions?
             ;;
        image)
             make image TARGET=$TEST_TARGET
             # rename the image to include git sha:
             mv $IMAGE $IMAGE_GIT
             # compress, otherwise downloads take forever
             xz -1 $IMAGE_GIT
             ;;
        kernel)
             make kernel TARGET=$TEST_TARGET
             # FIXME: do we want to make it available via github actions?
             ;;
        *)
             echo "ERROR: BUILD_TYPE must be specified: (blobby_kernel|image|kernel)"
             exit 1
             ;;
    esac
