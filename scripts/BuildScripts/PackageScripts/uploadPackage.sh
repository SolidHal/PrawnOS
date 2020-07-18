#!/bin/bash

set -e

# upload the target package to the official prawnos apt repo
# (of course this will only work if you can authenticate with the repo)

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


#example ~/.dput.cf
# [deb.prawnos.com]
# fqdn = deb.prawnos.com
# method = scp
# login = debian
# incoming = /var/www/repos/apt/debian/incoming
# allow_unsigned_uploads = true
# ssh_config_options = Port=2222



if [ -z "$1" ]
then
    echo "No .changes file supplied"
    exit 1
fi

dput deb.prawnos.com $1
