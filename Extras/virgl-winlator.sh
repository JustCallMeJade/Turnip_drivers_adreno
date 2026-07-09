#!/usr/bin/env bash
set -uo pipefail

workdir="$(pwd)/workdir"
install_dir="$workdir/install_dir"

# Enable source repositories (required for apt build-dep)
apt update

# Install build dependencies for Mesa
apt build-dep -y mesa

# Install additional tools
apt install -y wget zip git pkg-config meson ninja-build

# Create working directories
mkdir -p "$workdir"
mkdir -p "$install_dir"

cd "$workdir"

# Clone Mesa
git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa

cd mesa

wget -O bruh.diff https://github.com/lfdevs/mesa-for-android-container/commit/a0274209044a75402ec309bee18edeb0cbe6282c.diff
# Apply patches
git apply --3way --whitespace=fix bruh.patch

# Configure Mesa
meson setup build \
    --prefix="$install_dir" \
    -Dplatforms=x11 \
    -Dvulkan-drivers= \
    -Dglx=xlib \
    -Dllvm=disabled \
    -Dgallium-drivers=virgl \
    -Dopengl=true \
    -Degl=disabled \
    -Dgles2=disabled \
    -Dshared-glapi=enabled \
    -Dgallium-va=disabled \
    -Dc_args="-Wno-error"

# Build and install
ninja -C build install

echo
echo "Build completed successfully."
echo "Installed to:"
echo "  $install_dir"
