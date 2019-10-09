#!/bin/bash

echo "

This Patch allows you to select all Chromebook Layouts.
For Default Behaiviour, select chromebook_m in /etc/default/keyboard or
Chromebook (most models) | Search overlay in yout DE Keyboard Selector.

Other Options:
chromebook_ralt			Chromebook (most models) | Right alt overlay
chromebook_m			Chromebook (most models) | Search overlay | F keys mapped to media keys
chromebook_m_ralt		Chromebook (most models) | Right alt overlay | F keys mapped to media keys
chromebook_falco		Chromebook Falco/Pixel/Pixel2 | Search overlay
chromebook_falco_ralt		Chromebook Falco/Pixel/Pixel2 | Right alt overlay
chromebook_m_falco		Chromebook Falco/Pixel/Pixel2 | Search overlay | F keys mapped to media keys
chromebook_m_falco_ralt		Chromebook Falco/Pixel/Pixel2 | Right alt overlay | F keys mapped to media keys
+chromebook_no_m		Chromebook (most models) | No overlay | F keys mapped to media keys

"

sudo ./xkbpatch/patchxkb.sh