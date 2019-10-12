#!/bin/bash

#Install PrawnOS to the internal emmc, this will partition the internal emmc
#and erase ALL data on it


# This file is part of PrawnOS (http://www.prawnos.com)
# Copyright (c) 2018 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.

RESOURCES=/InstallResources
# Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk0 for an sd card
BOOT_DEVICE=$(mount | head -n 1 | cut -d ' ' -f 1)


echo "--------------------------------------------------------------------------------------------------------"
echo "PrawnOS Install To Wherever You Want Script"
echo "Sets up boot and root partition, encryption, and copies the filesystem from the bootable media"
echo "This script can be quit and re-ran at any point"
echo "--------------------------------------------------------------------------------------------------------"
read -p "This will ERASE ALL DATA ON THE TARGET DEVICE and reboot when finished, do you want to continue? [y/N]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    # dmesg -D
    
    while true; do
    	echo "If installing to a USB flash drive, make sure only one USB storage device is plugged in"
    	echo "Make VERY SURE you don't install it to the device you just booted from!!"
    	read -p "install to: external (S)D, external (U)SB Storage or (I)nternal eMMC: " ESU
    	case $ESU in
        	[Ss]* ) TARGET=SD; break;;
        	[Uu]* ) TARGET=USB; break;;
        	[Ii]* ) TARGET=MMC; break;;
        	* ) echo "Please answer I, S or U";;
    	esac
	done

    if [ "$TARGET" = "USB" ]
	then
	
	TARGETDEV="/dev/sda"
	TARGETDEVP="/dev/sda"
	STARTSECTOR=8192
	
	fi
	
	if [ "$TARGET" = "SD" ]
	then
	
	TARGETDEV="/dev/mmcblk0"
	TARGETDEVP="/dev/mmcblk0p"	
		STARTSECTOR=8192
	
	fi
	
	if [ "$TARGET" = "MMC" ]
	then
	
	TARGETDEV="/dev/mmcblk2"
	TARGETDEVP="/dev/mmcblk2p"	
	STARTSECTOR=20480
	#dmesg -D
	
	fi
	
	umount "$TARGETDEVP"1	  || /bin/true
    umount "$TARGETDEVP"2    || /bin/true
    umount "$TARGETDEVP"3    || /bin/true

	
    echo Writing partition map
    DISK_SZ="$(blockdev --getsz "$TARGETDEV")"
    echo Total disk size is: $DISK_SZ
    
    KERNELSIZE=65536
    BOOTPARTSTARTSECTOR=$(($STARTSECTOR + $KERNELSIZE))
    
    BOOTPARTSIZE=409600 # 200MB
    
    ROOTPARTSTARTSECTOR=$(($BOOTPARTSTARTSECTOR + $BOOTPARTSIZE))
    
    ROOTPARTSIZE=$(($DISK_SZ - $ROOTPARTSTARTSECTOR)) #this SHOULD work as we count in sectors, so would be aligned
    
    # Clear at least partition table and first to partitions kernel and boot (around 400MB)
    echo "Fucking up the start"
    dd if=/dev/zero of="$TARGETDEV" bs=50M count=11
    # Main idea is to completely, but fast, fuck up the whole device, so even delete the secondary GPT table
    echo "Fucking up the end"
    dd if=/dev/zero of="$TARGETDEV" bs=512 count=2048 seek=$((`blockdev --getsz "$TARGETDEV"` - 2048))

    sleep 1
    echo "Trying partprobe"

    partprobe

    echo "Asking parted nicely to mob up shit"
    parted -s "$TARGETDEV" mklabel gpt

    echo "Trying cgpt repair to no avail"
    cgpt repair

    sleep 1

    # Clear GPT Partition Table on Target Device
    cgpt create "$TARGETDEV"

    
    # add kernel partition,                                 label,   successful flag, tries flag, priority    
    cgpt add -i 1 -t kernel -b $STARTSECTOR -s $KERNELSIZE -l Kernel -S 1             -T 5         -P 10     "$TARGETDEV"
    
    # add boot partition for initramfs
    cgpt add -i 2 -t data -b $BOOTPARTSTARTSECTOR -s $BOOTPARTSIZE -l Boot "$TARGETDEV"

	# compare calculated rootpartsize and solidhal approach
	
	ROOTPARTEND=`cgpt show "$TARGETDEV" | grep 'Sec GPT table' | awk '{print $1}'`
  	ROOTPARTSIZE_SOLID=$(($ROOTPARTEND - $ROOTPARTSTARTSECTOR))

	echo "calculated: " $ROOTPARTSIZE # i forgot the 33 sectors of the second GPT Table here, but will leave it, so you can learn.
	echo "Solid calc: " $ROOTPARTSIZE_SOLID # totally a more solid approach

	cgpt add -i 3 -t data -b $ROOTPARTSTARTSECTOR -s $ROOTPARTSIZE_SOLID -l Root "$TARGETDEV"
	
	# this enables detection of partitions by sfdisk and other older utilities and makes mounts possible
	cgpt boot -i 1 -p "$TARGETDEV"

	# set the primary gpt table to IGNOREME
	cgpt legacy -p $TARGETDEV
	
	# create ext4 filesystems
	
	# mkfs.ext4 -F -b 1024 -m 0 "$TARGETDEVP"2 $(($BOOTPARTSIZE / 2))
  	# mkfs.ext4 -F -b 1024 -m 0 "$TARGETDEVP"3 $(($ROOTPARTSIZE_SOLID / 2))
	

	# copy the pri gpt partition header for diff
	dd if="$TARGETDEV" bs=512 skip=1 count=1 of=prigptheader.img
	
	# copy the pri gpt partition table for diff
	dd if="$TARGETDEV" bs=512 skip=2 count=32 of=prigpttable.img
	
	# copy the sec gpt partition table to the primary
	dd if="$TARGETDEV" bs=512 skip=$ROOTPARTEND count=32 of=secgpttable.img
	# dd if=secgpttable.img bs=512 seek=2 of="$TARGETDEV"
	
	# copy the sec gpt partition header to the primary (test)
	SECGPTHEADERSTART=`cgpt show "$TARGETDEV" | grep 'Sec GPT header' | awk '{print $1}'`
	dd if="$TARGETDEV" bs=512 skip=$SECGPTHEADERSTART count=1 of=secgptheader.img
	# dd if=secgptheader.img bs=512 seek=1 of="$TARGETDEV"
	
	echo "Will run partprobe and sleep for 10 seconds now or mkfs.ext4 will not recognize the new partitions"
    partprobe $TARGETDEV
    sleep 10

    #dmesg -E

    echo Writing kernel partition
    dd if=/dev/zero of="$TARGETDEVP"1 bs=512 count=65536
    # this will totally fail on a decrypted device
    
    echo "Boot device detected is $BOOT_DEVICE"
    
        while true; do
    	echo "Please select the device containing the kernel partition. The kernel partition"
    	echo "is not encrypted, so you totally can select the device even when luks is enabled"
    	read -p "Read kernel from: external (S)D, external (U)SB Storage or (I)nternal eMMC: " ESU
    	case $ESU in
        	[Ss]* ) KERNELFROMP="/dev/mmcblk0p"; break;;
        	[Uu]* ) KERNELFROMP="/dev/sda"; break;;
        	[Ii]* ) KERNELFROMP="/dev/mmcblk2p"; break;;
        	* ) echo "Please answer I, S or U";;
    	esac
	done
    
    
    echo "sfdisk DUMP:"
    echo "............"
    
    sfdisk -d "$TARGETDEV"
    
    echo "cgpt show:"
    echo ".........."
    
    cgpt show "$TARGETDEV"

    
    dd if="$KERNELFROMP"1 of="$TARGETDEVP"1

    BOOT_DEV="$TARGETDEVP"2
    ROOT_DEV="$TARGETDEVP"3
    CRYPTO=false

    #ready /boot
    mkfs.ext4 -F $BOOT_DEV
    mkdir -p /mnt/boot
    mount $BOOT_DEV /mnt/boot

    #Handle full disk encryption
    echo "Would you like to setup full disk encrytion using LUKs/DmCrypt?"
    select yn in "Yes" "No"
    do
        case $yn in
        Yes )
            CRYPTO=true
            # Since iteration count is based on cpu power, and the rk3288 isn't as fast as a usual
            # desktop cpu, manually supply -i 15000 for security at the cost of a slightly slower unlock
            echo "Now to setup the password you would like to use to unlock the encrypted root partition at boot"
            cryptsetup -q -y -s 512 luksFormat -i 15000 $ROOT_DEV || exit 1
            echo "Now unlock the newly created encrypted root partition so we can mount it and install the filesystem"
            cryptsetup luksOpen $ROOT_DEV luksroot_inst || exit 1
            ROOT_DEV=/dev/mapper/luksroot_inst
            #set the root encryption flag
            touch /mnt/boot/root_encryption
            break
            ;;
        No )
        	break
        	;;
        * )
            echo "Invalid Option, please enter Yes or No, 1 or 2"
            ;;
        esac
    done

    echo Writing Filesystem, this will take about 4 minutes...
    mkfs.ext4 -F -b 1024 $ROOT_DEV
    mkdir -p /mnt/mmc/
    mount $ROOT_DEV /mnt/mmc
    rsync -ah --info=progress2 --info=name0 --numeric-ids -x / /mnt/mmc/
    #Remove the live-fstab and install a base fstab
    rm /mnt/mmc/etc/fstab
    if [[ $CRYPTO == "true" ]]
    then
        echo "/dev/mapper/luksroot / ext4 defaults,noatime 0 1" > /mnt/mmc/etc/fstab # this is fine, because upon boot will be mounted as luksroot.
    else
        echo "$ROOT_DEV / ext4 defaults,noatime 0 1" > /mnt/mmc/etc/fstab
    fi
    umount $BOOT_DEV
    umount $ROOT_DEV
    echo Running fsck on boot, then on root
    e2fsck -p -f $BOOT_DEV
    e2fsck -p -f $ROOT_DEV
    if [[ $CRYPTO == "true" ]]
    then
        # unmount and close encrypted storage
        cryptsetup luksClose luksroot_inst
    fi
    echo Rebooting... Please remove the usb drive once shutdown is complete
    # reboot
fi

echo Exiting
