git clone --recurse-submodules https://review.coreboot.org/coreboot.git
cd coreboot
apt install zlib1g-dev gnat
make crossgcc-aarch64
