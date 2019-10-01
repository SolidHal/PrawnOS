su -

apt build-dep mesa
git clone https://gitlab.freedesktop.org/mesa/mesa -b "19.2"
cd mesa
mkdir build
cd build
meson .. . -Ddri-drivers= -Dvulkan-drivers= -Dgallium-drivers=panfrost,kmsro -Dlibunwind=false
ninja install

reboot