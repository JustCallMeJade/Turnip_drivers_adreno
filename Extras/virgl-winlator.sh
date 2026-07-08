#!/bin/bash

sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources

apt update

apt build-dep mesa -y

apt install wget zip git pkg-config

git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa

mkdir workdir

cd workdir

cd mesa

wget https://github.com/alexvorxx/Mesa-VirGL/commit/6a734cc1e1c6565fe688d0d05d37ecc3b2f330d2
wget https://github.com/alexvorxx/Mesa-VirGL/commit/e67a72f8691dd450a527ab262b676e6fb21ec602

git apply --3way --whitespace=fix 6a734cc1e1c6565fe688d0d05d37ecc3b2f330d2.patch
git apply --3way --whitespace=fix e67a72f8691dd450a527ab262b676e6fb21ec602.patch

meson setup build -Dplatforms=x11 -Dvulkan-drivers= -Dglx=xlib -Dllvm=disabled -Dgallium-drivers=virgl -Dopengl=true -Degl=disabled -Dc_args="-Wno-error"

ninja -C build install
