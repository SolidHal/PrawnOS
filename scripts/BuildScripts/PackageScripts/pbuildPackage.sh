#!/bin/bash

set -e

# build the supplied package using pbuilder
# satisfies build dependencies if necessary


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
    echo "No pbuilder chroot supplied"
    exit 1
fi

if [ -z "$3" ]
then
    echo "No pbuilder RC supplied"
    exit 1
fi

if [ -z "$4" ]
then
    echo "No pbuilder hooks directory supplied"
    exit 1
fi

if [ -z "$5" ]
then
    echo "No prawnos apt repo directory supplied"
    exit 1
fi

if [ -z "$6" ]
then
    echo "No prawnos apt repo sources.list line supplied"
    exit 1
fi

PACKAGE_NAME=$1
PBUILDER_CHROOT=$2
PBUILDER_RC=$3
PBUILDER_HOOKS=$4
PRAWNOS_LOCAL_APT_REPO=$5
PRAWNOS_LOCAL_APT_SOURCE=$6

#set to true when rebuild packages for anew distro or rebuild the apt repo so the original source tar is included in the upload
PDEBUILD_ORIGINAL_SOURCE="false"

PACKAGE_DIR=$PWD


# only defined if there are build deps we need to satisfy
PACKAGE_LOCAL_BUILD_DEPS=$7

DEBUILD_OPTS=""
if [[ $PDEBUILD_ORIGINAL_SOURCE == "true" ]]; then
	DEBUILD_OPTS="--debbuildopts -sa"
fi


if [[ $PACKAGE_LOCAL_BUILD_DEPS == "" ]]; then
	  echo Building $PACKAGE_NAME
    cd src
    pdebuild --configfile $PBUILDER_RC \
                      --buildresult $PACKAGE_DIR \
		      $DEBUILD_OPTS \
                      -- \
                      --hookdir $PBUILDER_HOOKS \
                      --basetgz $PBUILDER_CHROOT

else
	  echo Satisfying local build deps for $PACKAGE_NAME
	  for dep in $PACKAGE_LOCAL_BUILD_DEPS ; do \
		    make build_package BUILD_PACKAGE=$dep -C .. ; \
	      done
    rm -f $PRAWNOS_LOCAL_APT_REPO/Packages
	  cd $PRAWNOS_LOCAL_APT_REPO && dpkg-scanpackages . /dev/null > Packages
	  echo $PACKAGE_NAME build deps satisfied
    cd $PACKAGE_DIR
	  echo Building $PACKAGE_NAME
	  cd src
    pdebuild --configfile $PBUILDER_RC \
                      --buildresult $PACKAGE_DIR \
		      $DEBUILD_OPTS \
                      -- \
                      --override-config \
                      --basetgz $PBUILDER_CHROOT \
                      --hookdir $PBUILDER_HOOKS \
                      --bindmounts $PRAWNOS_LOCAL_APT_REPO \
                      --othermirror "$PRAWNOS_LOCAL_APT_SOURCE"
fi

