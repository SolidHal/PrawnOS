#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 priv-key out-file"
	exit 1
fi

openssl req -new -key "$1" -days 36500 -utf8 -nodes -batch \
	-x509 -outform PEM -out "$2" \
	-config <(cat <<-EOF
		[ req ]
		distinguished_name = req_distinguished_name
		string_mask = utf8only
		prompt = no
		[ req_distinguished_name ]
		commonName = sforshee
		EOF
	)
