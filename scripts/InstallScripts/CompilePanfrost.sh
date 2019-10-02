su -

apt -y build-dep mesa
apt -y install mesa-utils
git clone https://gitlab.freedesktop.org/mesa/mesa -b master
cd mesa
mkdir build
cd build
meson .. . -Ddri-drivers= -Dvulkan-drivers= -Dgallium-drivers=panfrost,kmsro -Dlibunwind=false
ninja install

apt -y remove llvm-7-dev
apt -y autoremove

reboot
