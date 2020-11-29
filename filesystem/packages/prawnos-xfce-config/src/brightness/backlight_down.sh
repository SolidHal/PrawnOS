#!/bin/bash
DEV="/sys/class/backlight/backlight"
BL="$(cat $DEV/brightness)"
if [ "$BL" -eq 0 ]; then
	exit 0
fi
if [ "$BL" -lt 5 ]; then
	BL="$((BL - 1))"
else
	BL="$((BL - ( BL / 4 )))"
fi
echo "$BL" > "$DEV/brightness"
