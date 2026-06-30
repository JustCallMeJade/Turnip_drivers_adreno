#!/bin/bash -e

workdir="$(pwd)/turnip_workdir"
mesasrc="https://gitlab.freedesktop.org/mesa/mesa.git"
VERSION="$(cat "$workdir/mesa/VERSION)""
PATCH_1="https://raw.githubusercontent.com/newb7171/Turnip_drivers_adreno/main/Gpu-Hacks.patch"
PATCH_2="https://raw.githubusercontent.com/newb7171/Turnip_drivers_adreno/main/KGSL-hacks-whitebelyash.diff"
PATCH_4="https://gitlab.freedesktop.org/Pipetto-crypto/mesa/-/commit/d264c66f9950cb2331c22c21172a07520fb38c68.diff"
PATCH_5="https://gitlab.freedesktop.org/Pipetto-crypto/mesa/-/commit/96c4cb07b2a52124021c807f2c1ad4ab1f1cbf9c.diff"

echo "Only works in debian Arm64!!! press Ctrl + C to exit"
echo "Installing build dependencies..."

sed -i '/^Types:/ s/$/ deb-src/' /etc/apt/sources.list.d/debian.sources
    
apt-get update
apt-get build-dep mesa -y -qq > /dev/null 2>&1
apt-get build-dep libarchive -y -qq > /dev/null 2>&1

apt-get install -y pkg-config git cmake wget zip patchelf libclc-21-dev -qq > /dev/null 2>&1

mkdir -p "$workdir"
cd "$workdir"

mkdir -p "$workdir/turnip"

rm -rf "$workdir/r29"
rm -rf "$workdir/mesa"
rm -f "$workdir/android-ndk-r29-linux-aarch64.tar.gz"

git clone $mesasrc --depth=1
cd mesa

rm -f VERSION

wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/VERSION

for patch in \
"$PATCH_1" \
"$PATCH_2" \
"$PATCH_4" \
"$PATCH_5"
do
    wget "$patch"
done

wget https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/42489.diff
wget https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/35924.diff

git apply Gpu-Hacks.patch
patch -p1 -i d264c66f9950cb2331c22c21172a07520fb38c68.diff
patch -p1 -i 96c4cb07b2a52124021c807f2c1ad4ab1f1cbf9c.diff

echo "#define TUGEN8_DRV_VERSION \"$VERSION\"" > ./src/freedreno/vulkan/tu_version.h

export CC=clang
export CXX=clang++
export AR=llvm-ar
export RANLIB=llvm-ranlib
export STRIP=llvm-strip
export OBJDUMP=llvm-objdump
export OBJCOPY=llvm-objcopy
export LDFLAGS="-fuse-ld=lld"

rm -rf build-android-aarch64

meson setup build-android-aarch64 \
    --prefix "$workdir/turnip" \
    -Dbuildtype=debugoptimized \
    -Dstrip=true \
    -Dplatforms=x11 \
    -Dvideo-codecs=all \
    -Dgallium-drivers= \
    -Dvulkan-drivers=freedreno \
    -Dvulkan-beta=true \
    -Dfreedreno-kmds=kgsl \
    -Degl=disabled

ninja -C build-android-aarch64 install

cd "$workdir/turnip/lib"

echo "build complete."
exit 0
