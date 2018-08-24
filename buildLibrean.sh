#!/bin/sh -xe

#Build everything

#Get sudo
sudo echo "Thanks."
#Build kernel WITHOUT SUDO, building the kernel with sudo is bad practice
./buildKernel.sh
#build os WITH sudo, debootstrap requires sudo
sudo ./buildDebian.sh
