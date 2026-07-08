#!/bin/bash

sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources

apt update

apt build-dep mesa -y

apt install wget zip git pkg-config

git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa

mkdir workdir

cd workdir

cd mesa

wget https://github.com/alexvorxx/Mesa-VirGL/commit/f6cc3760680ba706c06f54f4d45e7ac8930241da.patch
wget https://github.com/alexvorxx/Mesa-VirGL/commit/9cc60fdb4ad6d29340d38c98f3e7b849e9249780.patch
wget https://github.com/alexvorxx/Mesa-VirGL/commit/208a22f98af7f56c7d0026de74d814d1860cb385.patch

git apply --3way --whitespace=fix f6cc3760680ba706c06f54f4d45e7ac8930241da.patch
git apply --3way --whitespace=fix 9cc60fdb4ad6d29340d38c98f3e7b849e9249780.patch
git apply --3way --whitespace=fix 208a22f98af7f56c7d0026de74d814d1860cb385.patch

meson setup build -Dplatforms=x11 -Dvulkan-drivers= -Dglx=xlib -Dllvm=disabled -Dgallium-drivers=virgl -Dopengl=true -Degl=disabled -Dc_args="-Wno-error"

ninja -C build install
