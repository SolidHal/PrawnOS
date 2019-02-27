#! /bin/bash

#Connect to wifi
wpa_passphrase PotatoMuncher gimmethosetots > wpa.conf
wpa_supplicant -i wlan0 -c wpa.conf &
dhclient wlan0

#download the debian image 
wget https://cdimage.debian.org/debian-cd/current/armhf/iso-dvd/debian-9.8.0-armhf-DVD-1.iso
