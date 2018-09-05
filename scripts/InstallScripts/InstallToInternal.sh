#!/bin/bash

#Install PrawnOS to the internal emmc, this will partition the internal emmc
#and erase ALL data on it


RESOURCES=/InstallResources

read -p "This will ERASE ALL DATA ON THE INTERNAL STORAGE (EMMC) and reboot when finished, do you want to continue? [Y/n]" -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo Writing partition map
    sfdisk /dev/mmcblk2 < $RESOURCES/mmc.partmap
    echo Writing kernel partition
    dd if=/dev/sda1 of=/dev/mmcblk2p1
    echo Writing Filesystem, this will take a moment...
    #Set the post install script to run after reboot
    ./$RESOURCES/runonce.sh $RESOURCES/InstallPackages.sh
    dd if=/dev/sda2 of=/dev/mmcblk2p2 bs=50M
    echo Expanding Filesystem
    e2fsck -p /dev/mmcblk2p2
    resize2fs /dev/mmcblk2p2
    echo Rebooting... Please remove the usb drive once shutdown is complete
fi

echo Exiting
