#!/bin/bash
set -uo pipefail

workdir="$(pwd)/turnip_workdir"
ndk="$workdir/r29/toolchains/llvm/prebuilt/linux-x86_64/bin" #yes r29 is the directory
sysroot="$workdir/r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
mesasrc="https://gitlab.freedesktop.org/mesa/mesa.git"

PATCH_1="https://raw.githubusercontent.com/newb7171/Turnip_drivers_adreno/main/Gpu-Hacks.patch"
PATCH_2="https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/tu_gen8.patch"
PATCH_3="https://github.com/lfdevs/mesa-for-android-container/commit/0a60c9c4108200fda20016b594dcf8806f29a28e.diff"
PATCH_4="https://github.com/lfdevs/mesa-for-android-container/commit/4bae24252a344c47a2afcd0fbd238d83bbc29f46.diff"
PATCH_5="https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/39751.patch"
PATCH_6="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/fix_a8xx_dev_info.py"
PATCH_7="https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/40159.diff"
PATCH_8="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/fix_gralloc_flushall.py"
PATCH_9="https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/42159.patch"
PATCH_10="https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/42489.patch"
PATCH_11="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/apply_perf_variant.py"
PATCH_12="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/disable_64b_image_atomics.py"
PATCH_13="https://github.com/lfdevs/mesa-for-android-container/commit/6338905ad3e8767bf5e5b04ffbbc6c3d9ed3d8e2.patch"
PATCH_14="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/apply_a7xx_gen2_ubwc_hint.py"
PATCH_15="https://raw.githubusercontent.com/WinNative-Emu/Drivers/main/patches/apply_balance_variant.py"
PATCH_16="https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/42953.diff"

PATCH_URLS=(
    "$PATCH_1" "$PATCH_2" "$PATCH_3" "$PATCH_4" "$PATCH_5"
    "$PATCH_6" "$PATCH_7" "$PATCH_8" "$PATCH_9" "$PATCH_10"
    "$PATCH_11" "$PATCH_12" "$PATCH_13" "$PATCH_14" "$PATCH_15" "$PATCH_16"
)

# Patches applied via `git apply`
GIT_APPLY_PATCHES=(
    Gpu-Hacks.patch
    39751.patch
    42159.patch
    42489.patch
    6338905ad3e8767bf5e5b04ffbbc6c3d9ed3d8e2.patch
)

# Patches applied via classic `patch -p1` (diffs git apply chokes on)
PATCH_P1_PATCHES=(
    40159.diff
    42953.diff
    0a60c9c4108200fda20016b594dcf8806f29a28e.diff
    4bae24252a344c47a2afcd0fbd238d83bbc29f46.diff
)

# Python-based patch scripts, chmod +x'd then executed
PY_PATCH_SCRIPTS=(
    apply_perf_variant.py
    disable_64b_image_atomics.py
    apply_a7xx_gen2_ubwc_hint.py
    apply_balance_variant.py
    fix_a8xx_dev_info.py
    fix_gralloc_flushall.py
)

# sed fixups: "pattern|replacement|file"
SED_FIXUPS=(
    's/anb->handle->/((const native_handle_t \*)anb->handle)->/g|src/vulkan/runtime/vk_android.c'
    's/typedef const native_handle_t\* buffer_handle_t;/typedef void\* buffer_handle_t;/g|include/android_stub/cutils/native_handle.h'
    's/, hnd->handle/, (void \*)hnd->handle/g|src/util/u_gralloc/u_gralloc_fallback.c'
    's/native_buffer->handle->/((const native_handle_t \*)native_buffer->handle)->/g|src/vulkan/runtime/vk_android.c'
)

deps="git pkg-config cmake git build-essential wget patchelf zip"
VERSION_GITHUB="26.3.0-V2.0"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

select_api_version() {
    if [[ -z "${API_VER:-}" ]]; then
        echo "API_VER is not set. Select an API version:"

        local api_versions=()
        for i in {27..36}; do
            api_versions+=("$i")
        done

        local ver
        select ver in "${api_versions[@]}"; do
            if [[ -n "$ver" ]]; then
                API_VER="$ver"
                export API_VER
                break
            fi
            echo "Invalid selection."
        done
    fi
}

select_build_variant() {
    if [[ -z "${BUILD_VARIANT:-}" ]]; then
        echo "BUILD_VARIANT is not set. Select a build variant:"

        local variant
        select variant in p p1 p2; do
            if [[ -n "$variant" ]]; then
                BUILD_VARIANT="$variant"
                export BUILD_VARIANT
                break
            fi
            echo "Invalid selection."
        done
    fi
}

install_build_dependencies() {
    echo "Only works in debian Arm64!!! press Ctrl + C to exit"
    echo "Installing build dependencies..."

    sudo sed -i '/^Types:/{/deb-src/! s/$/ deb-src/;}' /etc/apt/sources.list.d/debian.sources

    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get build-dep mesa -y -qq > /dev/null 2>&1
    sudo apt-get build-dep libarchive -y -qq > /dev/null 2>&1

    for dep in $deps; do
        sudo apt install -y "$dep" > /dev/null 2>&1
    done
}

setup_workdir() {
    mkdir -p "$workdir" && cd "$workdir"
    mkdir -p "$workdir/turnip"

    local deleted
    for deleted in \
        "$workdir/r29" \
        "$workdir/mesa" \
        "$workdir/android-ndk-r29-linux-aarch64.tar.gz"
    do
        rm -rf "$deleted"
    done
}

download_ndk() {
    cd "$workdir"
    wget -q -nv https://github.com/SnowNF/ndk-aarch64-linux/releases/download/0.0.2/android-ndk-r29-linux-aarch64.tar.gz
    tar -xzf android-ndk-r29-linux-aarch64.tar.gz
}

clone_mesa() {
    cd "$workdir"
    git clone "$mesasrc" --depth=1
    cd mesa

    git config user.name "Turnip-Builder"
    git config user.email "sdddxd86@gmail.com"

    rm -f VERSION
    wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/main/VERSION

    export VERSION="$(cat "$workdir/mesa/VERSION")"
}

download_patches() {
    cd "$workdir/mesa"
    local patch
    for patch in "${PATCH_URLS[@]}"; do
        wget "$patch" -q -nv
    done
}

apply_git_patches() {
    cd "$workdir/mesa"
    local patch
    for patch in "${GIT_APPLY_PATCHES[@]}"; do
        echo "Applying $patch..."
        git apply "$patch"
    done
}

apply_diff_patches() {
    cd "$workdir/mesa"
    local patch
    # git apply doesn't work well with diffs
    for patch in "${PATCH_P1_PATCHES[@]}"; do
        echo "Applying $patch..."
        patch -p1 -i "$patch"
    done
}

apply_python_patch_scripts() {
    cd "$workdir/mesa"
    local patch
    for patch in "${PY_PATCH_SCRIPTS[@]}"; do
        chmod +x "$patch"
        ./"$patch"
    done
}

apply_gen8_patch() {
    cd "$workdir/mesa"
    git am --whitespace=fix tu_gen8.patch
}

apply_sed_fixups() {
    cd "$workdir/mesa"
    local entry pattern file
    for entry in "${SED_FIXUPS[@]}"; do
        pattern="${entry%%|*}"
        file="${entry##*|}"
        sed -i "$pattern" "$file" || true
    done

    git add -A
}

write_version_header() {
    cd "$workdir/mesa"
    echo "#define TUGEN8_DRV_VERSION \"v$VERSION\"" > ./src/freedreno/vulkan/tu_version.h
}

setup_toolchain_env() {
    export PATH="$ndk:$PATH"
    export CC=clang
    export CXX=clang++
    export AR=llvm-ar
    export RANLIB=llvm-ranlib
    export STRIP=llvm-strip
    export OBJDUMP=llvm-objdump
    export OBJCOPY=llvm-objcopy
    export LDFLAGS="-fuse-ld=lld"
}

write_cross_files() {
    cd "$workdir/mesa"

    cat <<EOF > android-aarch64.txt
[binaries]
ar = '$ndk/llvm-ar'
c = ['$ndk/aarch64-linux-android$API_VER-clang', '--sysroot=$sysroot', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments', '-Wno-error']
cpp = ['$ndk/aarch64-linux-android$API_VER-clang++', '--sysroot=$sysroot', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments', '-Wno-error']
c_ld = '$ndk/ld.lld'
cpp_ld = '$ndk/ld.lld'
strip = '$ndk/llvm-strip'
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=$sysroot/usr/lib/pkg-config', 'PKG_CONFIG_SYSROOT_DIR=$sysroot', '/usr/bin/pkg-config']

[built-in options]
c_args = ['--sysroot=$sysroot', '-Wno-error']
cpp_args = ['--sysroot=$sysroot']
c_link_args = ['--sysroot=$sysroot']
cpp_link_args = ['--sysroot=$sysroot']

[properties]
sys_root = '$sysroot'

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

    cat <<EOF > native.txt
[binaries]
c = 'clang'
cpp = 'clang++'
ar = 'llvm-ar'
strip = 'llvm-strip'
c_ld = 'ld.lld'
cpp_ld = 'ld.lld'
pkg-config = 'pkg-config'

[build_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF
}

build_mesa() {
    cd "$workdir/mesa"
    rm -rf build-android-aarch64

    meson setup build-android-aarch64 \
        --cross-file android-aarch64.txt \
        --native-file native.txt \
        --prefix "$workdir/turnip" \
        -Dbuildtype=debugoptimized \
        -Dstrip=true \
        -Dplatforms=android \
        -Dvideo-codecs=all \
        -Dplatform-sdk-version="$API_VER" \
        -Dandroid-stub=true \
        -Dgallium-drivers= \
        -Dvulkan-drivers=freedreno \
        -Dvulkan-beta=true \
        -Dfreedreno-kmds=kgsl \
        -Degl=disabled \
        -Dandroid-strict=false

    ninja -C build-android-aarch64 -j"$(nproc)" install
}

package_turnip() {
    cd "$workdir/turnip/lib"

    echo "packaging turnip"

    patchelf --set-soname vulkan.adreno.so libvulkan_freedreno.so
    mv libvulkan_freedreno.so vulkan.adreno.so

    cat <<EOF > meta.json
{
"schemaVersion": 1,
"name": "Mesa Turnip v$VERSION",
"description": "Built from Mesa source + GPU hacks",
"author": "JustCallMeJade",
"packageVersion": "1",
"vendor": "Mesa3D",
"driverVersion": "Vulkan 1.4.354",
"minApi": 28,
"libraryName": "vulkan.adreno.so"
}
EOF

    zip -9 "$workdir/turnip/Turnip-v$VERSION.zip" vulkan.adreno.so meta.json

    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        echo "VERSION=$VERSION_GITHUB" >> "$GITHUB_ENV"
    fi

    echo "build complete."
}

# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------

run_all() {
    select_api_version
    select_build_variant
    install_build_dependencies
    setup_workdir
    download_ndk
    clone_mesa
    download_patches
    apply_git_patches
    apply_diff_patches
    apply_python_patch_scripts
    apply_gen8_patch
    apply_sed_fixups
    write_version_header
    setup_toolchain_env
    write_cross_files
    build_mesa
    package_turnip
}

run_all
exit 0
