#!/bin/bash

cd /InstallResources/xkb

cp ./compat/* /usr/share/X11/xkb/compat/
cp ./keycodes/* /usr/share/X11/xkb/keycodes/
cp ./symbols/* /usr/share/X11/xkb/symbols/

patch /usr/share/X11/xkb/rules/base < ./rules/base.chromebook.patch
patch /usr/share/X11/xkb/rules/base.lst < ./rules/base.lst.chromebook.patch
patch /usr/share/X11/xkb/rules/base.xml < ./rules/base.xml.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev < ./rules/evdev.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev.lst < ./rules/evdev.lst.chromebook.patch
patch /usr/share/X11/xkb/rules/evdev.xml < ./rules/evdev.xml.chromebook.patch

cp keyboard /etc/default/keyboard

