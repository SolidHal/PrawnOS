#!/bin/bash

set -x
set -e

#extract the regulatory db file from the build filesystem


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2024 Eva Emmerich <eva@evaemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.

#Ensure Sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo, or as root:"
    echo "sudo $0 $*"
    exit 1
fi

if [ -z "$1" ]
then
    echo "No base file system image supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No output location supplied"
    exit 1
fi

BASE=$1
OUT_DIR=$2


outmnt=$(mktemp -d -p "$(pwd)")
outdev=$(losetup -f)

if [ ! -f $BASE ]
then
    echo "No base filesystem, run 'make filesystem' first"
    exit 1
fi

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is sometimes required to properly clean the loop devices and ensure a clean build
cleanup() {
    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1

    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1
}

trap cleanup INT TERM EXIT

losetup -P $outdev $BASE
#mount the root filesystem
if [ "$TARGET" == "${PRAWNOS_ARM64_RK3588_SERVER}" ]; then
    mount -o noatime ${outdev}p3 $outmnt
elif [ "$TARGET" == "${PRAWNOS_ARM64_RK3588}" ]; then
    mount -o noatime ${outdev}p3 $outmnt
else
    mount -o noatime ${outdev}p2 $outmnt
fi

cp $outmnt/usr/lib/firmware/regulatory.db.p7s-upstream $OUT_DIR/regulatory.db.p7s
cp $outmnt/usr/lib/firmware/regulatory.db-upstream $OUT_DIR/regulatory.db


# do a non-error cleanup
umount -l $outmnt > /dev/null 2>&1
rmdir $outmnt > /dev/null 2>&1
losetup -d $outdev > /dev/null 2>&1
echo "DONE!"
trap - INT TERM EXIT