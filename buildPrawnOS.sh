#!/bin/sh -xe

#Build everything

#Get sudo
sudo echo "Thanks."
#Build kernel WITHOUT SUDO, building the kernel with sudo is bad practice
#Once, sometime in the kernel version 2 days building the kernel with sudo broke the
#The system it was built on
./scripts/buildKernel.sh
#build os WITH sudo, debootstrap requires sudo
sudo ./scripts/buildDebianFs.sh
