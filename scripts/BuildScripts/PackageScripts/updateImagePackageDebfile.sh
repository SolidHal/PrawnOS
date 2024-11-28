#!/bin/bash

set -x
set -e

# update the debian/changelog of the kernel packages when the kernel version changes
# returns the current version

# This file is part of PrawnOS (https://www.prawnos.com)
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

if [ -z "$1" ]
then
    echo "No debian src folder supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No deb version supplied"
    exit 1
fi


DEBSRC=$1
DEBVER=$2

cd $DEBSRC
# check the supplied kver against the current kver
CUR_DEBVER=$(dpkg-parsechangelog --show-field Version)

if [ "$DEBVER" != "$CUR_DEBVER" ]; then
    debchange --no-conf --newversion $DEBVER -M release $DEBVER
    debchange --no-conf --release "" -M
    echo Updated package to $DEBVER
else
    echo Kept package at $DEBVER
fi

