#!/usr/bin/env bash
#
# Replaces the local src/vulkan/wsi/ folder with the version from
# brunodev85/mesa3d-custom (turnip-25.2.0 branch), downloading every file
# via wget from raw.githubusercontent.com.
#
# Usage:
#   ./sync_wsi.sh /path/to/mesa
#   ./sync_wsi.sh            # defaults to current directory
#
# The file list below was taken from a live listing of that repo path at
# the time this script was written. GitHub doesn't let raw.githubusercontent.com
# list a directory's contents (it only serves individual files by exact
# path), so the file names have to be known ahead of time rather than
# discovered at runtime. If files are later added/removed/renamed
# upstream, add/remove them from FILES below to match.

set -euo pipefail

REPO="brunodev85/mesa3d-custom"
BRANCH="main"
REMOTE_DIR="turnip-25.2.0/src/vulkan/wsi"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${REMOTE_DIR}"

FILES=(
  meson.build
  wsi_common.c
  wsi_common.h
  wsi_common_display.c
  wsi_common_display.h
  wsi_common_drm.c
  wsi_common_drm.h
  wsi_common_headless.c
  wsi_common_metal.c
  wsi_common_metal_layer.h
  wsi_common_metal_layer.m
  wsi_common_private.h
  wsi_common_queue.h
  wsi_common_wayland.c
  wsi_common_win32.cpp
  wsi_common_x11.c
)

MESA_ROOT="${1:-.}"

if [[ ! -d "$MESA_ROOT" ]]; then
  echo "ERROR: $MESA_ROOT is not a directory" >&2
  exit 1
fi

# Locate src/vulkan/wsi under MESA_ROOT by finding wsi_common.h, rather
# than assuming MESA_ROOT itself is the repo root.
TARGET_DIR=""
while IFS= read -r -d '' candidate; do
  TARGET_DIR="$(dirname "$candidate")"
  break
done < <(find "$MESA_ROOT" -type f -path "*/src/vulkan/wsi/wsi_common.h" -print0 2>/dev/null)

if [[ -z "$TARGET_DIR" ]]; then
  echo "ERROR: could not find src/vulkan/wsi/wsi_common.h anywhere under $MESA_ROOT" >&2
  echo "       (is this a Mesa checkout?)" >&2
  exit 1
fi

echo "Target directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

fail_count=0
for name in "${FILES[@]}"; do
  url="${BASE_URL}/${name}"
  dest="${TARGET_DIR}/${name}"
  tmp="${dest}.tmp.$$"

  if wget -q -O "$tmp" "$url"; then
    if [[ -s "$tmp" ]]; then
      mv -f "$tmp" "$dest"
      echo "  $name: downloaded"
    else
      rm -f "$tmp"
      echo "  $name: downloaded but empty, skipped" >&2
      fail_count=$((fail_count + 1))
    fi
  else
    rm -f "$tmp"
    echo "  $name: FAILED to download from $url" >&2
    fail_count=$((fail_count + 1))
  fi
done

echo
if [[ "$fail_count" -eq 0 ]]; then
  echo "Done: all ${#FILES[@]} files synced to $TARGET_DIR"
else
  echo "Done with $fail_count failure(s) out of ${#FILES[@]} files -- see above." >&2
  exit 1
fi
