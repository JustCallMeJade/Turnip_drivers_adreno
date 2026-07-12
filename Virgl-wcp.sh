#!/bin/bash

set -o pipefail

workdir="$(pwd)/workdir"
install_dir="$workdir/install"

alias install='
dnf update -y > /dev/null 2>&1
dnf builddep mesa -y > /dev/null 2>&1
dnf install git cmake python3 wget patchelf -y > /dev/null 2>&1
dnf install xcb-* -y > /dev/null 2>&1
dnf install x11-* -y > /dev/null 2>&1
'

shopt -s extglob expand_aliases

mkdir -p "$workdir" "$install_dir"
cd "$workdir"

echo "Installing build deps.."

install

echo "Cloning mesa.."

git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa

export VERSION="$(cat VERSION)"

echo "Patching VirGL for Xlib"

wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/Xlib-VirGL.py

python3 Xlib-VirGL.py

echo "Compiling..."

meson setup build \
    --prefix "$install_dir" \
    -Dplatforms=x11 \
    -Dglx=xlib \
    -Dvulkan-drivers= \
    -Dgallium-va=disabled \
    -Dbuildtype=debugoptimized \
    -Dllvm=disabled \
    -Dshared-llvm=disabled \
    -Dgallium-drivers=virgl \
    -Dshared-glapi=enabled \
    -Dopengl=true \
    -Degl=disabled \
    -Dgles2=disabled \
    -Dgles1=disabled \
    -Dvideo-codecs=all \
    -Dstrip=true

ninja -C build -j"$(nproc)" install

echo "Patching libGL..."

cd "$install_dir/lib64"

patchelf --set-soname libGL.so.1.7.0 libGL.so.1.5.0
mv libGL.so.1.5.0 libGL.so.1.7.0
ln -sf libGL.so.1.7.0 libGL.so.1

if [ -L libGL.so ]; then
    ln -sf libGL.so.1 libGL.so
fi

echo "Packaging VirGL..."

cd "$install_dir"

mkdir -p VirGL

cp -P lib64/libGL.so.1 VirGL/

cat > profile.json <<EOF
{
  "type": "VirGL",
  "versionName": "$VERSION",
  "versionCode": 1,
  "description": "VirGL-$VERSION Compiled by JustCallMeJade [https://github.com/JustCallMeJade]",
  "files": [
    {
      "source": "VirGL/libGL.so.1",
      "target": "\${libdir}/libGL.so.1"
    }
  ]
}
EOF

tar -cJf "VirGL-$VERSION.tar.xz" VirGL profile.json
mv "VirGL-$VERSION.tar.xz" "VirGL-$VERSION.wcp"

echo "Done! ✅"

exit 0
