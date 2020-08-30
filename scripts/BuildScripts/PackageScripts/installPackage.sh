#!/bin/bash

set -e

# install the target package into the target location


# This file is part of PrawnOS (https://www.prawnos.com)
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


if [ -z "$1" ]
then
    echo "No package name supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No install location supplied"
    exit 1
fi

PACKAGE_NAME=$1
INSTALL_LOCATION=$2

if [ ! -f "$PACKAGE_NAME" ]; then
    echo "Error $PACKAGE_NAME must be built first"
    exit 1
fi

echo Installing $PACKAGE_NAME to $INSTALL_LOCATION
cp $PACKAGE_NAME $INSTALL_LOCATION
