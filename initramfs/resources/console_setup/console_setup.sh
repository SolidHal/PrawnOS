#! /bin/sh
# A crude much-simplified clone of setupcon for use in the initramfs.
# modified and simplified further for PrawnOS

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES="/dev/tty[1-6]"

CHARMAP="UTF-8"
CODESET=Uni2
FONTFACE="Fixed"
FONTSIZE="8x16"

VIDEOMODE=

echo "Setting up console..."

# FONTSIZE
if [ -z "$FONTSIZE" -o "$FONTSIZE" = guess ]; then
    FONTSIZE=16
fi
case "$FONTSIZE" in
    8x*)
        FONTSIZE=${FONTSIZE#*x}
        ;;
    *x8)
        FONTSIZE=${FONTSIZE%x*}
        ;;
    *x*)
        a=${FONTSIZE%x*}
        b=${FONTSIZE#*x}
        if [ "$a" -lt "$b" ]; then
            FONTSIZE=${b}x${a}
        fi
        ;;
esac

verbose=
# verbose='>/dev/null 2>&1'


for i in 1 2 3 4 5 6; do
	[ -c /dev/tty$i ] || mknod /dev/tty$i c 4 $i
done


for console in $ACTIVE_CONSOLES; do
	[ -w $console ] || continue

	if [ "$CHARMAP" = UTF-8 ] || [ -z "$ACM$CHARMAP" ]; then
		printf '\033%%G' >$console
	else
		printf '\033%%@' >$console
	fi

	if [ "$FONT" ]; then
		FONT="/etc/console-setup/${FONT##*/}"
		FONT="${FONT%.gz}"
	else
		FONT="/etc/console-setup/$CODESET-$FONTFACE$FONTSIZE.psf"
	fi
	if [ -f "$FONT" ] || [ -f "$FONT.gz" ]; then
		if type consolechars >/dev/null 2>&1; then
			eval consolechars -v --tty=$console -f "$FONT" $verbose
		elif type setfont >/dev/null 2>&1; then
			eval setfont -v -C $console "$FONT" $verbose
		fi
	fi

	if [ "$ACM" ]; then
		ACM="/etc/console-setup/${ACM##*/}"
		ACM="${ACM%.gz}"
	else
		ACM="/etc/console-setup/$CHARMAP.acm"
	fi
	if [ -f "$ACM" ] || [ -f "$ACM.gz" ]; then
		if type consolechars >/dev/null 2>&1; then
			eval consolechars -v --tty=$console --acm "$ACM" \
				$verbose
		elif type setfont >/dev/null 2>&1; then
			eval setfont -v -C "$console" -m "$ACM" $verbose
		fi
	fi

	if type kbd_mode >/dev/null 2>&1; then
		if [ "$CHARMAP" = UTF-8 ] || [ -z "$ACM" ]; then
			kbd_mode -u <$console
		else
			kbd_mode -a <$console
		fi
	fi
done

if [ -f "/etc/console-setup/cached_${CHARMAP}_del.kmap.gz" ] && type loadkeys >/dev/null; then
  echo "Loading console keys..."
	eval loadkeys "/etc/console-setup/cached_${CHARMAP}_del.kmap.gz" $verbose
fi

echo "Console setup complete"
exit 0
