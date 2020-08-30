#!/bin/sh
# /etc/acpi/default.sh
# Default acpi script that takes an entry for all actions

set $*

group=${1%%/*}
action=${1#*/}
device=$2
id=$3
value=$4

log_unhandled() {
	logger "ACPI event unhandled: $*"
}

case "$group" in
	jack)
		case "$id" in
			'plug')
				amixer -D hw:0 cset name='Left Speaker Mixer Left DAC Switch' off
				amixer -D hw:0 cset name='Right Speaker Mixer Right DAC Switch' off
				amixer -D hw:0 cset name='Headphone Switch Left' on
                                amixer -D hw:0 cset name='Headphone Switch Right' on
				;;
			'unplug')
				amixer -D hw:0 cset name='Left Speaker Mixer Left DAC Switch' on
                                amixer -D hw:0 cset name='Right Speaker Mixer Right DAC Switch' on
				amixer -D hw:0 cset name='Headphone Switch Left' off
                                amixer -D hw:0 cset name='Headphone Switch Right' off
				;;
			*) uhd $+;;
		esac
		log_unhandled $*
	;;
	button)
		case "$action" in
			#power)
					#pm-suspend
			#		log_unhandled $*
			#	;;

			lid)
				case "$id" in
					close) if [ $(cat /sys/class/power_supply/gpio-charger/online) -eq 0 ]; then
                                                        pm-suspend
                                                fi;;
					open) :;;
					*) uhd $*;;
				esac
				log_unhandled $*
				;;

			*)	log_unhandled $* ;;
		esac
		;;

	*)	log_unhandled $* ;;
esac
