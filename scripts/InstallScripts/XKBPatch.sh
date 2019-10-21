#!/bin/bash

echo "

This Patch allows you to select all Chromebook Layouts.
For default behaviour, select chromebook_m in /etc/default/keyboard or
Chromebook (most models) | Search overlay in your DE Keyboard Selector.

Other Options:
chromebook_ralt			Chromebook (most models) | Right alt overlay
chromebook_m			Chromebook (most models) | Search overlay | F keys mapped to media keys
chromebook_m_ralt		Chromebook (most models) | Right alt overlay | F keys mapped to media keys
chromebook_falco		Chromebook Falco/Pixel/Pixel2 | Search overlay
chromebook_falco_ralt		Chromebook Falco/Pixel/Pixel2 | Right alt overlay
chromebook_m_falco		Chromebook Falco/Pixel/Pixel2 | Search overlay | F keys mapped to media keys
chromebook_m_falco_ralt		Chromebook Falco/Pixel/Pixel2 | Right alt overlay | F keys mapped to media keys
chromebook_no_m		Chromebook (most models) | No overlay | F keys mapped to media keys

After this patch, chromebook_m will be the default in /etc/default/keyboard with us layout

"

sudo /InstallResources/xkb/patchxkb.sh

