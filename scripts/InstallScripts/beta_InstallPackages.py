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


import click
from prompt_toolkit.shortcuts import button_dialog
from tools import get_device_model

# option helpers
def validate_res(res, expected):
    if res not in expected:
        raise ValueError(f"{res} is not a valid option, expected one of {expected}")

# option handlers
de_answers = ["xfce", "gnome"]
de_hint ="Choose a desktop envorionment to install. If you are unsure, pick Xfce" 
def ask_de(options):
    result = None
    if (opt := options.get("de", None)):
        result = opt
    else:
        result = button_dialog(
            title='Install Desktop Environment',
            text=de_hint,
            buttons=[
                ('Xfce', "xfce"),
                ('Gnome', "gnome"),
            ],
        ).run()
    validate_res(result, de_answers)
    return result


#TODO ensure all options end up in the all_answers map
all_answers = {"de" : de_answers}
def ask_all(options):
    answers = all_answers
    answers["de"] = ask_de(options)

    return answers




def main(options):
    #TODO take map of user prompted options to skip prompting
    answers = ask_all(options)

    model = get_device_model()
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

