#!/bin/sh -e

#Adjust Gnome Touchpad settings


# This file is part of PrawnOS (http://www.prawnos.com)
# Copyright (c) 2020 G. Dallas Dye <gdallasdye@gmail.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


#Natural scrolling is un-natural
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
#Tap to click is natural
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
