#!/bin/bash -e

#See the block of "echos" in main() for description of this script

# This file is part of PrawnOS (https://www.prawnos.com)
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

# Grab the boot device, which is either /dev/sda for usb or /dev/mmcblk(0/1) for an sd card
BOOT_DEVICE=$(mount | head -n 1 | cut -d '2' -f 1)

### SHARED CONST AND VARS
RESOURCES=/etc/prawnos/install/resources
SCRIPTS=/etc/prawnos/install/scripts

# TODO: when these scripts are packaged, place these in a shared script instead of in every file that needs them
device_veyron_speedy="Google Speedy"
device_veyron_minnie="Google Minnie"
device_veyron_mickey="Google Mickey"
device_gru_kevin="Google Kevin"
device_gru_bob="Google Bob"

get_device() {
    local device=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
    echo $device
}

get_emmc_devname() {
    local devname=$(ls /dev/mmcblk* | grep -F boot0 | sed "s/boot0//")
    if [ -z "$devname" ]
    then
        echo "Unknown device! can't determine emmc devname. Please file an issue with the output of fdisk -l if you get this on a supported device"; exit 1;;
    fi
    echo $devname
}


get_sd_devname() {
    local device=$(get_device)
    case "$device" in
        $device_veyron_speedy) local devname=mmcblk0;;
        $device_veyron_minnie) local devname=mmcblk0;;
        $device_veyron_mickey) local devname="";;
        $device_gru_kevin) local devname=mmcblk0;;
        $device_gru_bob) local devname=mmcblk0;;
        * ) echo "Unknown device! can't determine sd card devname. Please file an issue with the output of fdisk -l if you get this on a supported device"; exit 1;;
    esac
    echo $devname
}

### END SHARED CONST AND VARS



main() {
    echo "---------------------------------------------------------------------------------------------------------------------"
    echo "PrawnOS Install or Expand Script"
    echo "Installation sets up the internal emmc partitions, root encryption, and copies the filesystem from the"
    echo "current boot device to the target device. The target device cannot be the current boot device"
    echo
    echo "Expansion simply targets the booted device, and expands the filesystem to fill the entire thing instead of just 2GB."
    echo "Because of this, root encryption cannot be setup"
    echo
    echo "For installation, this script can be quit and re-ran at any point."
    echo "Unfortunately for expansion this is not the case"
    echo "---------------------------------------------------------------------------------------------------------------------"
    echo
    echo "Expand or Install?: "
    echo "The currently booted device is ${BOOT_DEVICE}"
    while true; do
        read -r -p "[I]nstall or [E]xpand?" IE
        case $IE in
            [Ii]* ) install; break;;
            [Ee]* ) expand; break;;
            * ) echo "Please answer I or E";;
        esac
    done
}

#Now to pick the install target: internal, sd, or usb
#if target is usb, and boot device is usb, target is sdb
#and whether to enable crypto
install() {
    echo "Pick an install target. This can be the Internal Emmc, an SD card, or a USB device"
    echo "Please ensure you have only have the booted device and the desired target device inserted."
    echo "The currently booted device is ${BOOT_DEVICE}"
    while true; do
        read -r -p "[I]nternal Emmc, [S]D card, or [U]SB device?: " ISU
        case $ISU in
            [Ii]* ) TARGET=/dev/$(get_emmc_devname)p; TARGET_EMMC=true; break;;
            [Ss]* ) TARGET=/dev/$(get_sd_devname)p; TARGET_EMMC=false; break;;
            [Uu]* ) TARGET=USB; TARGET_EMMC=false; break;;
            * ) echo "Please answer I, S, or U";;
        esac
    done
    if [[ $TARGET == "USB" ]]
    then
        if [[ $BOOT_DEVICE == "/dev/sda" ]]
        then
            TARGET=/dev/sdb
        else
            TARGET=/dev/sda
        fi
    fi
    if [[ "$TARGET" == "$BOOT_DEVICE" ]]
    then
        echo "Can't install to booted device, please ensure you have *only* the booted device and target device inserted"
        exit
    fi

    #cut off the "p" if we are using an sd card or internal emmc, doesn't change TARGET if we are using usb
    TARGET_NO_P=$(echo $TARGET | cut -d 'p' -f 1)
    if [ ! -e $TARGET_NO_P ];
    then
        echo "${TARGET_NO_P} does not exist, have you plugged in your target sd card or usb device?"
        exit 1
    fi

    #Now on to the installation, basically copy InstallToInternal.sh
    while true; do
        read -r -p "This will ERASE ALL DATA ON ${TARGET_NO_P} and reboot when finished, do you want to continue? [y/N]" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done

    # Only try to unmount if the device is mounted
    # If it is, try anyway, the dd will (likely) take care of it anyway
    if findmnt ${TARGET}1 > /dev/null
    then
        umount ${TARGET}1 || /bin/true
    fi

    if findmnt ${TARGET}2 > /dev/null
    then
    umount ${TARGET}2 || /bin/true
    fi

    #only use the emmc_partition function for "special cases", aka veyron devices
    if [[ $TARGET == "/dev/mmcblk2p" ]] && $TARGET_EMMC
    then
        emmc_partition
    else
        external_partition $TARGET_NO_P
    fi

    KERNEL_PARTITION=${TARGET}1
    ROOT_PARTITION=${TARGET}2
    CRYPTO=false

    echo Writing kernel to partition $KERNEL_PARTITION
    dd if=/dev/zero of=$KERNEL_PARTITION bs=512 count=65536
    dd if=${BOOT_DEVICE}1 of=$KERNEL_PARTITION

    #Handle full disk encryption
    echo "Would you like to setup full disk encrytion using LUKs/DmCrypt?"
    select yn in "Yes" "No"
    do
        case $yn,$REPLY in
        Yes,*|*,Yes )
            CRYPTO=true
            # Since iteration count is based on cpu power, and the rk3288 isn't as fast as a usual
            # desktop cpu, manually supply -i 15000 for security at the cost of a slightly slower unlock
            dmesg -n 2
            echo "Enter the password you would like to use to unlock the encrypted root partition at boot"
            cryptsetup -q -y -s 512 luksFormat -i 15000 $ROOT_PARTITION || exit 1
            echo "Now unlock the newly created encrypted root partition so we can mount it and install the filesystem"
            cryptsetup luksOpen $ROOT_PARTITION luksroot || exit 1
            dmesg -n 7
            ROOT_PARTITION=/dev/mapper/luksroot
            break
            ;;
        No,*|*,No )
            break
            ;;
        * )
            echo "Invalid Option, please enter Yes or No, 1 or 2"
            ;;
        esac
    done

    echo Creating ext4 filesystem on root partition
    mkfs.ext4 -F -b 1024 $ROOT_PARTITION
    INSTALL_MOUNT=/mnt/install_mount
    mkdir -p $INSTALL_MOUNT/
    mount $ROOT_PARTITION $INSTALL_MOUNT/
    echo Syncing live root filesystem with new root filesystem, this will take about 4 minutes...
    rsync -ah --info=progress2 --info=name0 --numeric-ids -x / $INSTALL_MOUNT/
    #Remove the live-fstab and install a base fstab
    rm $INSTALL_MOUNT/etc/fstab
    echo "${ROOT_PARTITION} / ext4 defaults,noatime 0 1" > $INSTALL_MOUNT/etc/fstab

    while true; do
        read -r -p "Install a desktop environment and the supporting packages? [Y/n]" ins
        case $ins in
            [Yy]* ) install_packages $INSTALL_MOUNT; break;;
            [Nn]* ) break;;
            * ) echo "Please answer y or n";;
        esac
    done

    # final setup:
    dmesg -D
    welcome
    setup_users $INSTALL_MOUNT
    setup_hostname $INSTALL_MOUNT
    dmesg -E

    umount $ROOT_PARTITION

    echo Running fsck
    e2fsck -p -f $ROOT_PARTITION
    if [[ $CRYPTO == "true" ]]
    then
        # unmount and close encrypted storage
        # let things settle, otherwise cryptsetup complainssss
        sleep 2
        cryptsetup luksClose luksroot
    fi
    echo "Please remove the booted device after power off is complete"
    while true; do
        read -r -p "Reboot? [y/N]" re
        case $re in
            [Yy]* ) reboot;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done

}

#Setup partition map on internal emmc
emmc_partition() {
    #disable dmesg, writing the partition map tries to write the the first gpt table, which is unmodifiable
    dmesg -D
    echo Writing partition map to internal emmc
    DISK_SZ="$(blockdev --getsz /dev/mmcblk2)"
    echo Total disk size is: $DISK_SZ
    if [ $DISK_SZ = 30785536 ]
    then
        echo Detected Emmc Type 1
        sfdisk /dev/mmcblk2 < $RESOURCES/mmc.partmap || true

    elif [ $DISK_SZ = 30777344 ]
    then
        echo Detected Emmc Type 2
        sfdisk /dev/mmcblk2 < $RESOURCES/mmc_type2.partmap || true
    else
        echo ERROR! Not a known EMMC type, please open an issue on github or send SolidHal an email with the Total disk size reported above
        echo Try a fallback value? This will allow installation to continue, at the cost of a very small amount of disk space. This may not work.
        select yn in "Yes" "No"
        do
            case $yn,$REPLY in
                Yes,*|*,Yes )
                    echo Trying Emmc Type 2
                    sfdisk /dev/mmcblk2 < $RESOURCES/mmc_type2.partmap || true
                    break
                    ;;
                * )
                    echo "Invalid Option, please enter Yes or No, 1 or 2"
                    ;;
            esac
        done
    fi
    dmesg -E
}

#Setup partition map for external bootable device, aka usb or sd card
external_partition() {
    EXTERNAL_TARGET=$1
    kernel_start=8192
    kernel_size=65536
    #wipe the partition map, cgpt doesn't like anything weird in the primary or backup partition maps
    sgdisk -Z $EXTERNAL_TARGET
    partprobe $EXTERNAL_TARGET
    #make the base gpt partition map
    parted --script $EXTERNAL_TARGET mklabel gpt
    cgpt create $EXTERNAL_TARGET
    #must use cgpt to make the kernel partition, as we need the -S, -T, and -P variables
    cgpt add -i 1 -t kernel -b $kernel_start -s $kernel_size -l Kernel -S 1 -T 5 -P 10 $EXTERNAL_TARGET
    #Now the main filesystem
    #cgpt doesn't seem to handle this part correctly
    sgdisk -N 2 $EXTERNAL_TARGET
    #Set the type to "data"
    sgdisk -t 2:0700 $EXTERNAL_TARGET
    #Name it "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root $EXTERNAL_TARGET
    #Reload the partition mapping
    partprobe $EXTERNAL_TARGET
}

#simply expand to fill the current boot device
expand() {
    # need to strip the "p" if BOOT_DEVICE is an sd card or emmc
    BOOT_DEVICE_NO_P=$(echo $BOOT_DEVICE | cut -d 'p' -f 1)
    if [[ $BOOT_DEVICE == "/dev/$(get_emmc_devname)" ]]
    then
        echo "Can't expand to fill internal emmc, install will have done this already"
        exit
    fi
    #Make the boot partition fille the whole drive
    #Delete the partition
    sgdisk -d 2 $BOOT_DEVICE_NO_P
    #Make new partition map entry, with full size
    sgdisk -N 2 $BOOT_DEVICE_NO_P
    #Set the type to "data"
    sgdisk -t 2:0700 $BOOT_DEVICE_NO_P
    #Name it "properly" - Probably not required, but looks nice
    sgdisk -c 2:Root $BOOT_DEVICE_NO_P
    #Reload the partition mapping
    partprobe $BOOT_DEVICE_NO_P
    #Force the filesystem to fill the new partition
    resize2fs -f ${BOOT_DEVICE}2
    echo "/dev/${BOOT_DEVICE}2 / ext4 defaults,noatime 0 1" > /etc/fstab
    while true; do
        read -r -p "Install a desktop environment and the supporting packages? [Y/n]" ins
        case $ins in
            [Yy]* ) $SCRIPTS/InstallPackages.sh; reboot;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n";;
        esac
    done

    dmesg -D
    welcome
    setup_users
    setup_hostname
    dmesg -E
}

# helper for install_packages()/setup_users()
chroot_wrapper() {
    local mountpoint="$1"
    shift

    mount -t proc proc "$mountpoint/proc/"
    mount --rbind /sys "$mountpoint/sys/"
    mount --rbind /dev "$mountpoint/dev/"

    chroot "$mountpoint" $@

    umount "$mountpoint/proc/"
    mount --make-rprivate /sys
    mount --make-rprivate /dev
    umount -R "$mountpoint/sys/"
    umount -R "$mountpoint/dev/"
}

#Install all packages, desktop environment to target device

install_packages() {
    TARGET_MOUNT=$1
    echo "Installing Packages"
    chroot_wrapper "$TARGET_MOUNT" .$SCRIPTS/InstallPackages.sh
    desktop=true
}

setup_hostname() {
    TARGET_MOUNT="$1"

    #this works fine in the expansion use as TARGET_MOUNT is simply empty

    while true; do
        read -r -p "Would you like to set a custom hostname (default: PrawnOS)? [y/n]" response
        case $response in
            [Yy]*)
                echo "-----Enter hostname:-----"
                read -r hostname
                # ensure no whitespace
                case "$hostname" in *\ *) echo hostnames may not contain whitespace;;  *) break;; esac
                ;;
            [Nn]* ) hostname="PrawnOS"; break;;
            * ) echo "Please answer y or n";;
        esac
    done

    # Setup /etc/hostname and /etc/hosts:
    echo -n "$hostname" > "$TARGET_MOUNT/etc/hostname"
    echo -n "127.0.0.1        $hostname" > "$TARGET_MOUNT/etc/hosts"
}

setup_users() {
    TARGET_MOUNT="$1"

    #handle when we use this for expansion
    if [ -z "$TARGET_MOUNT" ]
    then
        CHROOT_PREFIX=""

    else
        CHROOT_PREFIX="chroot_wrapper $TARGET_MOUNT"
    fi

    # Have the user set a root password
    echo "-----Enter a password for the root user-----"
    until $CHROOT_PREFIX passwd
    do
        echo "-----Enter a password for the root user-----"
        $CHROOT_PREFIX passwd
    done

    if [[ "$desktop" = "true" ]]; then
        #Force a safe username
        while true; do
            echo "-----Enter new username:-----"
                read -r username
                #ensure no whitespace
                case "$username" in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
            done
        until $CHROOT_PREFIX adduser "$username" --gecos "$username"
        do
            while true; do
                echo "-----Enter new username:-----"
                read -r username
                #ensure no whitespace
                case "$username" in *\ *) echo usernames may not contain whitespace;;  *) break;; esac
            done
        done
        $CHROOT_PREFIX usermod -a -G sudo,netdev,input,video,bluetooth "$username"
    fi
}


welcome() {
    echo ""
    echo ""
    echo ""

    cat $RESOURCES/ascii-icon.txt
    echo ""
    echo "*************Welcome To PrawnOS*************"
    echo ""
}

#call the main function, script technically starts here
#Organized this way so that main can come before the functions it calls
main "$@"; exit
