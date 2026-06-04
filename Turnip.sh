#!/bin/bash -e

set -uo pipefail

########################################
# SAFETY CHECK
########################################
echo "WARNING: Root required + deb-src must be enabled."
echo "Press A to continue, B to exit."

read -r input
case "$input" in
  A|a) echo "Starting build..." ;;
  B|b) exit 0 ;;
  *) exit 1 ;;
esac

########################################
# SYSTEM SETUP
########################################
echo "[1/10] Updating system..."
apt update --fix-missing && apt upgrade -y

echo "[2/10] Installing Mesa build dependencies..."
apt build-dep mesa -y

echo "[3/10] Installing required packages..."
apt install --fix-missing -y \
  git wget cmake pkg-config patchelf zip \
  meson ninja-build clang lld \
  expat libarchive-dev libxml2 libxml2-dev

########################################
# WORKSPACE
########################################
echo "[4/10] Creating workspace..."
mkdir -p /root/Turnip
cd /root/Turnip

echo "[5/10] Downloading NDK..."
wget -q https://github.com/SnowNF/ndk-aarch64-linux/releases/download/0.0.2/android-ndk-r29-linux-aarch64.tar.gz

tar -xf android-ndk-r29-linux-aarch64.tar.gz

export NDK=/root/r29/toolchains/llvm/prebuilt/linux-x86_64/bin

########################################
# MESA SOURCE
########################################
echo "[6/10] Cloning Mesa..."
git clone https://gitlab.freedesktop.org/mesa/mesa.git --depth 1
cd mesa

########################################
# MESON CONFIG
########################################
cat <<EOF > android-aarch64.txt
[binaries]
ar = '$NDK/llvm-ar'
c = '$NDK/aarch64-linux-android34-clang'
cpp = '$NDK/aarch64-linux-android34-clang++'
c_ld = '$NDK/ld.lld'
cpp_ld = '$NDK/ld.lld'
strip = '$NDK/llvm-strip'

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

cat <<EOF > native.txt
[build_machine]
c = 'clang'
cpp = 'clang++'
ar = 'llvm-ar'
strip = 'llvm-strip'
c_ld = 'ld.lld'
cpp_ld = 'ld.lld'
system = 'linux'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

########################################
# BUILD
########################################
echo "[7/10] Configuring build..."
meson setup build \
  --cross-file android-aarch64.txt \
  --native-file native.txt \
  --prefix /root/turnip \
  -Dbuildtype=release \
  -Dplatforms=android \
  -Dvulkan-drivers=freedreno \
  -Dgallium-drivers= \
  -Degl=disabled \
  -Dandroid-stub=true \
  -Dplatform-sdk-version=34

echo "[8/10] Building..."
ninja -C build -j"$(nproc)"

echo "[9/10] Installing..."
ninja -C build install

########################################
# OUTPUT LIB
########################################
cd /root/turnip/lib

patchelf --set-soname vulkan.ad07xx.so libvulkan_freedreno.so
mv libvulkan_freedreno.so vulkan.ad07xx.so

########################################
# VERSION DETECTION (CLEAN)
########################################
cd /root/Turnip/mesa

RAW_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
VERSION=$(echo "$RAW_TAG" | sed 's/[^0-9.]*//g')

NAME="A8XX Turnip v$VERSION"
ZIP="Turnip-v$VERSION.zip"

########################################
# PACKAGE
########################################
echo "[10/10] Packaging..."

cd /root/turnip/lib

cat <<EOF > meta.json
{
  "schemaVersion": 1,
  "name": "$NAME",
  "description": "Freedreno Turnip Vulkan driver built from source",
  "author": "JustCallMeJade",
  "vendor": "Mesa",
  "driverVersion": "Vulkan 1.4.335",
  "libraryName": "vulkan.ad07xx.so"
}
EOF

zip -r "$ZIP" vulkan.ad07xx.so meta.json

echo ""
echo "DONE"
echo "Name: $NAME"
echo "Output: /root/turnip/lib/$ZIP"
