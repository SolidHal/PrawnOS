#!/usr/bin/env python3


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2023 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.



from pathlib import Path

RESOURCES = Path(/etc/prawnos/install/resources)
SCRIPTS = Path(/etc/prawnos/install/scripts)

def get_device_model():
    f = open("/sys/firmware/devicetree/base/model", "r")
    model = f.read().strip()
    return model


# Grab the boot partition, which is either /dev/sda2 for usb or /dev/mmcblk(0/1)p2 for an sd card
def get_boot_partition():
    cmd = ["lsblk", "-oMOUNTPOINT,PKNAME",  "-P"]
    res = subprocess.run(cmd, check=True, capture_output=True, text=True)
    for line in res.stdout.split("\n"):
        if 'MOUNTPOINT="/"' in line:
            # line looks like: MOUNTPOINT="/" PKNAME="mmcblk1p2"
            #         or like: MOUNTPOINT="/" PKNAME="sda2"
            devname = line.split("PKNAME=")[1].strip('"')

    return f"/dev/{devname}"

# Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk(0/1) for an sd card
def get_boot_device():
    devname = get_boot_partition()
    # strip off the partition
    if "mmcblk" in devname:
        devname = devname[:-2]
    else:
        devname = devname[:-1]

    return devname

#TODO add wrapper for apt
# maybe use
# https://apt-team.pages.debian.net/python-apt/library/index.html


## Stubs for later use
def apt_install(packages):
    pass

def apt_remove(packages):
    pass

def apt_purge(packages):
    pass

## Helper tools for handling  user provided installation options
class OptHander():
    def __init__(opt, answers, hint, dialog):
        self.opt = opt
        self.aswers = answers
        self.hint = hint
        self.dialog = dialog

    def ask(options):
        result = None
        if (option := options.get(self.opt, None)):
            result = option
        else:
            result = self.dialog.run()
        if result not in self.answers:
            raise ValueError(f"{result} is not a valid option, expected one of {self.answers}")
        return result

def register_opt(all_handlers, opt, answers, dialog)
    handler = OptHander(opt, answers, hint, dialog)
    all_handlers[opt] = handler
    return handler

def ask_all(all_handlers, options):
    answers = {}
    for opt, handler in all_handlers.items():
        answers[opt] = handler(options)
    return answers

