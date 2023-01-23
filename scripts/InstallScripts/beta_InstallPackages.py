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
import package_lists as pl
import constants

# option handlers
all_handlers = {}

DE_OPT = "de"
DE_XFCE = "xfce"
DE_GNOME = "gnome"
DE_ANSWERS = [DE_XFCE, DE_GNOME]
DE_DIALOG = button_dialog(
            title='Install Desktop Environment',
            text="Choose a desktop envorionment to install. If you are unsure, pick Xfce",
            buttons=[
                ('Xfce', DE_XFCE),
                ('Gnome', DE_GNOME),
            ],
        )

libinstall.register_opt(all_handlers, DE_OPT, DE_ANSWERS, DE_DIALOG)



def main(options):
    #TODO take map of user prompted options to skip prompting
    answers = libinstall.ask_all(all_handlers, options)

    model = libinstall.get_device_model()
    print(model)
    print(answers)


    #TODO set the timezone, and the time
    packages = []
    ## General packages
    packages += pl.base_debs_download
    packages += pl.prawnos_base_debs_prebuilt_download

    ## Device Specific packages
    if "veyron" in model:
        packages += prawnos-veyron-config
    elif "gru" in model:
        packages += prawnos-gru-config

    ## DE Specific packages
    if answers[DE_OPT] == DE_GNOME:
        packages += gnome_debs_download
        packages += prawnos_gnome_debs_prebuilt_download

    elif answers[DE_OPT] = DE_XFCE:
        packages += xfce_debs_download
        packages += prawnos_xfce_debs_prebuilt_download

    libinstall.apt_install(packages)

    # clean up some broken packages, and some not necessary
    purge_packages = []
    # TODO figure out what packages are pulling these in
    purge_packages += gnome-software
    purge_packages += lilyterm
    # TODO debug why rotation is flipped
    # work around issue #234
    purge_packages += iio-sensor-proxy
    # remove light-locker, as it is broken see issue #56
    purge_packages += light-locker

    libinstall.apt_purge(purge_packages)

    #TODO need to wrap the following commands

    #$ apt clean -y
    #$ apt autoremove --purge -y

    # reload the CA certificate symlinks
    #$ update-ca-certificates --fresh

    #enable periodic TRIM
    #$ cp /lib/systemd/system/fstrim.{service,timer} /etc/systemd/system
    # systemctl enable fstrim.timer



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

