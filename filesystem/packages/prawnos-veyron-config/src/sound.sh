#!/bin/bash

case "$1" in
	jack/headphone)
		case "$3" in
			plug)
				amixer -D hw:0 cset name='Left Speaker Mixer Left DAC Switch' off
                                amixer -D hw:0 cset name='Right Speaker Mixer Right DAC Switch' off
                                amixer -D hw:0 sset 'Headphone Left' on
                                amixer -D hw:0 sset 'Headphone Right' on
			;;
			unplug)
				amixer -D hw:0 cset name='Left Speaker Mixer Left DAC Switch' on
                                amixer -D hw:0 cset name='Right Speaker Mixer Right DAC Switch' on
                                amixer -D hw:0 sset 'Headphone Left' off
                                amixer -D hw:0 sset 'Headphone Right' off
			;;
		esac
	;;
	jack/microphone)
		case "$3" in
			plug)
			;;
			unplug)
			;;
		esac
	;;
esac

