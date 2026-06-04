#!/bin/bash -e

set -uo pipefail

echo "[1/9] Verifying build output..."

if [ ! -f /root/turnip/lib/vulkan.ad07xx.so ]; then
    echo "ERROR: /root/turnip/lib/vulkan.ad07xx.so not found."
    echo "Run the first build script first."
    exit 1
fi

if [ ! -d /root/turnip ]; then
    echo "ERROR: /root/turnip missing."
    exit 1
fi

echo "[2/9] Detecting Mesa git version..."

MESA_DIR="/root/Turnip/mesa"
MESA_VERSION="unknown"

if [ -d "$MESA_DIR/.git" ]; then
    cd "$MESA_DIR"

    MESA_VERSION=$(git describe --tags --exact-match 2>/dev/null || true)

    if [ -z "$MESA_VERSION" ]; then
        MESA_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || true)
    fi

    if [ -z "$MESA_VERSION" ]; then
        MESA_VERSION="unknown"
    fi

    cd - >/dev/null
fi

echo "Mesa version: $MESA_VERSION"

echo "[3/9] Entering output directory..."
cd /root/turnip/lib

VERSION_NAME="A8XX Turnip v${MESA_VERSION}"

echo "[4/9] Creating meta.json..."
cat <<EOF > meta.json
{
  "schemaVersion": 1,
  "name": "A8XX Turnip v${MESA_VERSION}",
  "description": "mesa driver turnip compiled from source",
  "author": "JustCallMeJade",
  "packageVersion": "1",
  "vendor": "Mesa",
  "driverVersion": "Vulkan 1.4.335",
  "minApi": 26,
  "libraryName": "vulkan.ad07xx.so"
}
EOF

echo "[5/9] Installing zip tool if missing..."
apt update && apt install -y zip

ZIP_NAME="Turnip-v${MESA_VERSION}.zip"

echo "[6/9] Creating zip archive: $ZIP_NAME"
zip -r "$ZIP_NAME" vulkan.ad07xx.so meta.json

echo "[7/9] Verifying output..."
test -f "$ZIP_NAME" || { echo "ZIP creation failed"; exit 1; }

echo "[8/9] Summary"
echo "Version name: $VERSION_NAME"
echo "Zip name: $ZIP_NAME"

echo "[9/9] Done!"
echo "Output: $(pwd)/$ZIP_NAME"
