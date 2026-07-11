#!/bin/bash

set -uo pipefail

workdir=$(pwd)/workdir
install_dir=$workdir/install

shopt -s extglob

mkdir -p $workdir && mkdir -p $install_dir && cd workdir

echo "Installing build deps.."

dnf update -y > /dev/null 2>&1

dnf builddep mesa -y > /dev/null 2>&1 && dnf install git cmake python3 wget -y > /dev/null 2>&1 && dnf install xcb-* -y > /dev/null 2>&1 && dnf install x11-* -y > /dev/null 2>&1

echo "Cloning mesa.."

git clone https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa

export VERSION="$(git describe --tags --abbrev=0 | sed 's/^mesa-//')"

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
-Dbuildtype=release \
-Dllvm=disabled \
-Dgallium-drivers=virgl \
-Dshared-glapi=enabled \
-Dopengl=true \
-Degl=disabled \
-Dgles2=disabled \
-Dgles1=disabled

ninja -C build install

echo "Packaging VirGL..."

cd "$install_dir" && cd lib64 && rm -rf !(libGL.so.1) && cd .. && mv lib64 VirGL

cat > profile.json <<EOF
{
  "type": "VirGL",
  "versionName": "$VERSION",
  "versionCode": 1,
  "description": "VirGL-$VERSION Extract from Winlator-v7 [https://github.com/brunodev85/winlator]",
  "files": [
    {
      "source": "VirGL/libGL.so.1",
      "target": "\${libdir}/libGL.so.1"
    }
  ]
}
EOF

tar -cJf VirGL-$VERSION.tar.xz VirGL profile.json

mv VirGL-$VERSION.tar.xz VirGL-$VERSION.wcp

echo "Done!✅"

exit 0
