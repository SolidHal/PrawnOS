#!/bin/bash
DEV="/sys/class/backlight/backlight"
BL="$(cat "$DEV/brightness")"
MAX="$(cat "$DEV/max_brightness")"

if [ "$BL" -lt 5 ]; then
	BL="$((BL + 1))"
else
	BL="$((BL + ( BL / 4 )))"
fi
if [ "$BL" -gt "$MAX" ]; then
	BL="$MAX"
fi
echo "$BL" > "$DEV/brightness"
