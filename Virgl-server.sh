#!/bin/bash

shopt -s expand_aliases
workdir="$(pwd)/workdir"
install_dir="$workdir/install-dir"
mkdir -p "$workdir" && mkdir -p "$install_dir"
cd "$workdir"
alias install="dnf update -y && dnf builddep mesa -y && dnf install pkg-config git cmake epoxy gcc gcc-c++ meson ninja-build python3 pkg-config libepoxy-devel libdrm-devel mesa-libgbm-devel libX11-devel vulkan-loader-devel libva-devel -y"
alias compile="git clone --depth=1 https://gitlab.freedesktop.org/virgl/virglrenderer.git && cd virglrenderer && meson setup build -Dplatforms=glx && ninja -C build -j$(nproc) install"
install
compile
exit 0
