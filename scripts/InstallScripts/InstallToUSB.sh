#!/bin/bash

#Install PrawnOS to an external device, the first usb by default
apt install -y gdisk parted
#Make the boot partition fille the whole drive
#Delete the partition
sgdisk -d 2 /dev/sda
#Make new partition map entry, with full size
sgdisk -N 2 /dev/sda
#Set the type to "data"
sgdisk -t 2:0700 /dev/sda
#Name is "properly" - Probably not required, but looks nice
sgdisk -c 2:Root /dev/sda
#Reload the partition mapping
partprobe /dev/sda
#Force the filesystem to fill the new partition
resize2fs -f /dev/sda2
