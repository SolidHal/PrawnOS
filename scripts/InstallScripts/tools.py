#!/usr/bin/env python3


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2022 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


def get_device_model():
    f = open("/sys/firmware/devicetree/base/model", "r")
    model = f.read().strip()
    return model


#TODO add wrapper for apt
# maybe use
# https://apt-team.pages.debian.net/python-apt/library/index.html
