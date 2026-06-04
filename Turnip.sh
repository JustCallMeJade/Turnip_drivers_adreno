#!/bin/bash -e

set -uo pipefail

echo "[CI] Starting Turnip Freedreno build..."

echo "Root required + deb-src enabled."
echo "Press A to continue, B to exit."

read -r input
case "$input" in
  A|a) echo "Starting..." ;;
  B|b) exit 0 ;;
  *) exit 1 ;;
esac

########################################
# SYSTEM SETUP
########################################
apt update && apt upgrade -y
apt build-dep mesa -y

apt install -y \
  git wget cmake pkg-config patchelf zip \
  meson ninja-build clang lld \
  expat libarchive-dev libxml2 libxml2-dev

########################################
# WORKSPACE
########################################
mkdir -p /root/Turnip
cd /root/Turnip

wget -q https://github.com/SnowNF/ndk-aarch64-linux/releases/download/0.0.2/android-ndk-r29-linux-aarch64.tar.gz
tar -xf android-ndk-r29-linux-aarch64.tar.gz

export NDK=/root/r29/toolchains/llvm/prebuilt/linux-x86_64/bin

########################################
# MESA
########################################
git clone https://gitlab.freedesktop.org/mesa/mesa.git --depth 1
cd mesa

########################################
# MESON FILES (NO CCACHE)
########################################
cat <<EOF > android-aarch64.txt
[binaries]
ar = '$NDK/llvm-ar'
c = '$NDK/aarch64-linux-android34-clang'
cpp = '$NDK/aarch64-linux-android34-clang++'
c_ld = '$NDK/ld.lld'
cpp_ld = '$NDK/ld.lld'
strip = '$NDK/llvm-strip'
EOF

cat <<EOF > native.txt
[build_machine]
c = 'clang'
cpp = 'clang++'
ar = 'llvm-ar'
strip = 'llvm-strip'
c_ld = 'ld.lld'
cpp_ld = 'ld.lld'
EOF

########################################
# BUILD
########################################
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

ninja -C build -j"$(nproc)"
ninja -C build install

########################################
# OUTPUT
########################################
cd /root/turnip/lib

patchelf --set-soname vulkan.ad07xx.so libvulkan_freedreno.so
mv libvulkan_freedreno.so vulkan.ad07xx.so

cd /root/Turnip/mesa

RAW_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
VERSION=$(echo "$RAW_TAG" | sed 's/[^0-9.]*//g')

NAME="A8XX Turnip v$VERSION"
ZIP="Turnip-v$VERSION.zip"

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

echo "[CI] DONE"
echo "Output: /root/turnip/lib/$ZIP"
