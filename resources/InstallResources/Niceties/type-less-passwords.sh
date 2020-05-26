#!/bin/sh -e

#Type less passwords


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

#Use with caution. This script does not disable your login password.
#Use this if you're concerned about your password being watched or listened to.
#Or pair with autologin and hand off to family for panfrost testing :)

#First backup the sudoers, then replace it with a known good example
sudo cp /etc/sudoers /etc/sudoers.original
sudo cp sudoers.nopasswd /etc/sudoers

#Now disable password prompts in a graphical session
sudo cp disable-passwords.pkla /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
