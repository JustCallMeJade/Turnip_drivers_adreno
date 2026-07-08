#!/usr/bin/env bash
set -uo pipefail

workdir="$(pwd)/workdir"
install_dir="$workdir/install_dir"

# Enable source repositories (required for apt build-dep)
sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources

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

sed -i "/Xlib based GLX requires llvmpipe/ s/^/# /" meson.build

# Download patches
wget -O 6a734cc1.patch \
    https://github.com/alexvorxx/Mesa-VirGL/commit/6a734cc1e1c6565fe688d0d05d37ecc3b2f330d2.patch

wget -O e67a72f8.patch \
    https://github.com/alexvorxx/Mesa-VirGL/commit/e67a72f8691dd450a527ab262b676e6fb21ec602.patch

# Apply patches
git apply --3way --whitespace=fix 6a734cc1.patch
git apply --3way --whitespace=fix e67a72f8.patch

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
    -Dc_args="-Wno-error"

# Build and install
ninja -C build install

echo
echo "Build completed successfully."
echo "Installed to:"
echo "  $install_dir"
