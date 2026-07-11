#!/bin/bash

set -uo pipefail

workdir=$(pwd)/workdir
install_dir=$workdir/install

mkdir -p $workdir && mkdir -p $install_dir && cd workdir

dnf update -y

dnf builddep mesa -y && dnf install git cmake python3 wget -y && dnf install xcb-* -y && dnf install x11-* -y

git clone https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa

wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/Xlib-VirGL.py

python3 Xlib-VirGL.py

meson setup build \
--prefix "$install_dir" \
-Dplatforms=x11 \
-Dglx=xlib \
-Dvulkan-drivers= \
-Dgallium-va=disabled \
-Dbuildtype=release \
-Dllvm=disabled \
-Dgallium-drivers=virgl \
-Dshared-glapi=true

ninja -C build install

exit 0
