#!/usr/bin/env python3

# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2023 Eva Emmerich <eva@evaemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


import click
from prompt_toolkit.shortcuts import button_dialog
import libinstall
import constants

# globals
BOOT_DEVICE = libinstall.get_boot_device()
BOOT_PARTITION = libinstall.get_boot_partition()

# option handlers
all_handlers = {}

IE_OPT = "ie"
IE_INSTALL = "install"
IE_EXPAND = "expand"
IE_ANSWERS = [IE_INSTALL, IS_EXPAND]
IE_HINT = f"""
---------------------------------------------------------------------------------------------------------------------
PrawnOS Install or Expand Script
Installation sets up the internal emmc partitions, root encryption, and copies the filesystem from the
current boot device to the target device. The target device cannot be the current boot device

Expansion simply targets the booted device, and expands the filesystem to fill the entire thing instead of just 2GB.
Because of this, root encryption cannot be used when choosing expansion.

For installation, this script can be quit and re-ran at any point.
Unfortunately for expansion this is not the case
---------------------------------------------------------------------------------------------------------------------

Currently booted to: {BOOT_PARTITION}
"""
IE_DIALOG = button_dialog(
            title='Expand or Install?',
            text=IE_HINT,
            buttons=[
                ('Install', IE_INSTALL),
                ('Expand', IE_EXPAND),
            ],
        )

IE_HANDLER = libinstall.register_opt(all_handlers, IE_OPT, IE_ANSWERS, IE_DIALOG)


INSTALL_OPT = "install"
# TODO add handlers that get the emmc, sd, usb dev names.



def main(options):
    #TODO take map of user prompted options to skip prompting

    ie_answer = IE_HANDLER.ask(options)
    if IE_INSTALL == ie_answer:
        # install path
        pass

    elif IE_EXPAND == ie_answer:
        # expand path
        pass

    else:
        raise ValueError(f"{ie_answer} does not contain install or expand")


    model = libinstall.get_device_model()
    print(model)
    print(answers)


@click.command()
@click.option('--options_file', default=None)
def cli(options_file):
    if options_file:
        #TODO load the json options file if provided
        pass

    options = {}
    main(options)

if __name__ == '__main__':
    cli()

