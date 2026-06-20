#!/bin/bash

set -euo pipefail

workdir="$(pwd)/turnip_workdir"
ndk="$workdir/r29/toolchains/llvm/prebuilt/linux-x86_64/bin"
mesasrc="https://gitlab.freedesktop.org/mesa/mesa.git"
BUILD_VERSION="26.2.0-V5"
PATCH_1="https://raw.githubusercontent.com/newb7171/Turnip_drivers_adreno/main/Gpu-Hacks.patch"
PATCH_2="https://raw.githubusercontent.com/newb7171/Turnip_drivers_adreno/main/KGSL-hacks-whitebelyash.diff"

echo "Only works in debian Arm64!!! press Ctrl + C to exit"
echo "Installing build dependencies..."

pkg update && pkg upgrade -y
pkg install x11-repo
pkg install mesa libx11 python cmake clang git wget ninja
pip install mako meson setuptools pyyaml

pkg install -y pkg-config git cmake wget zip patchelf libclc glslang -qq

echo "setting up workdir"

mkdir -p "$workdir"
cd "$workdir"

mkdir -p "$workdir/turnip"

rm -rf "$workdir/r29"
rm -rf "$workdir/mesa"
rm -f "$workdir/android-ndk-r29-linux-aarch64.tar.gz"

git clone $mesasrc --depth=1
cd mesa

echo "applying patches..."

wget https://raw.githubusercontent.com/whitebelyash/mesa-unified/main/src/freedreno/common/freedreno_devices.py

rm -f src/freedreno/common/freedreno_devices.py

mv freedreno_devices.py src/freedreno/common

wget "$PATCH_1"
wget "$PATCH_2"
git apply Gpu-Hacks.patch
patch -p1 KGSL-hacks-whitebelyash.diff
git add -A

echo "#define TUGEN8_DRV_VERSION \"$BUILD_VERSION\"" > ./src/freedreno/vulkan/tu_version.h

export PATH="$workdir/bin:$ndk:$PATH"
export CC=clang
export CXX=clang++
export AR=llvm-ar
export RANLIB=llvm-ranlib
export STRIP=llvm-strip
export OBJDUMP=llvm-objdump
export OBJCOPY=llvm-objcopy
export LDFLAGS="-fuse-ld=lld"

echo "setting crossfiles and setting up mesa..."

rm -rf build-android-aarch64

meson setup build-android-aarch64 \
    --prefix "$workdir/turnip" \
    -Dbuildtype=debugoptimized \
    -Dplatforms=x11 \
    -Dvideo-codecs=all \
    -Dgallium-drivers= \
    -Dvulkan-drivers=freedreno \
    -Dvulkan-beta=true \
    -Dfreedreno-kmds=kgsl \
    -Degl=disabled \
    -Dllvm=disabled

echo "compiling mesa..."

ninja -C build-android-aarch64 install

cd "$workdir/turnip/lib"

echo "packaging turnip as .deb"

# Set up deb staging directory
PREFIX="data/data/com.termux/files"
PKGDIR="$workdir/deb_staging"
LIBDIR="$PKGDIR/$PREFIX/usr/lib"
ICDDIR="$PKGDIR/$PREFIX/usr/share/vulkan/icd.d"
DEBIANDIR="$PKGDIR/DEBIAN"

mkdir -p "$LIBDIR" "$ICDDIR" "$DEBIANDIR"

# Place the driver
cp vulkan.adreno.so "$LIBDIR/libvulkan_freedreno.so"

# Generate the ICD JSON
cat <<EOF > "$ICDDIR/freedreno_icd.aarch64.json"
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "/$PREFIX/usr/lib/libvulkan_freedreno.so",
        "api_version": "1.4.335"
    }
}
EOF

# Calculate installed size in KB
INSTALLED_SIZE=$(du -sk "$PKGDIR" | cut -f1)

# Generate DEBIAN/control
cat <<EOF > "$DEBIANDIR/control"
Package: mesa-turnip-adreno
Version: $BUILD_VERSION
Architecture: aarch64
Maintainer: JustCallMeJade
Installed-Size: $INSTALLED_SIZE
Depends: mesa
Section: libs
Priority: optional
Description: Mesa Turnip Vulkan driver for Adreno GPUs
 Open-source Vulkan driver for Qualcomm Adreno GPUs built from Mesa source.
 Targets the KGSL kernel mode driver on Android/Linux aarch64.
EOF

# Build the .deb
dpkg-deb --root-owner-group -Zxz --build "$PKGDIR" "$workdir/turnip/mesa-turnip-adreno_${BUILD_VERSION}_aarch64.deb"

echo "BUILD_VERSION=$BUILD_VERSION" >> $GITHUB_ENV

echo "build complete."
exit 0
