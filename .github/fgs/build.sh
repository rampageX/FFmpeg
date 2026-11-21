#!/usr/bin/env bash
# FGS Windows x64 native MSYS2/UCRT64 build. Input source has already been patched.
set -euo pipefail
if [[ $# -ne 2 ]]; then
    echo "Usage: build.sh SOURCE_DIRECTORY CHANNEL" >&2
    exit 2
fi
source_dir="$1"
channel="$2"
root_dir="$(pwd -P)"
prefix="$root_dir/stage/$channel"
mkdir -p "$prefix"
cd "$source_dir"
# Use stock SVT-AV1 from MSYS2; do not use SVT-AV1-HDR.
export PKG_CONFIG_PATH="/ucrt64/lib/pkgconfig:/ucrt64/share/pkgconfig"
./configure \
    --prefix="$prefix" \
    --target-os=mingw32 \
    --arch=x86_64 \
    --enable-gpl \
    --enable-version3 \
    --enable-shared \
    --disable-static \
    --disable-debug \
    --enable-runtime-cpudetect \
    --enable-vulkan \
    --enable-libplacebo \
    --enable-cuda-llvm \
    --enable-nvenc \
    --enable-nvdec \
    --enable-d3d11va \
    --enable-d3d12va \
    --enable-amf \
    --enable-libsvtav1 \
    --enable-libaom \
    --enable-libdav1d \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libmp3lame \
    --enable-libass \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libzimg \
    --enable-libsoxr \
    --enable-libjxl \
    --enable-libwebp \
    --enable-libopenjpeg \
    --enable-libsrt \
    --enable-gnutls \
    --enable-libvpl
echo "====== Configuration ======"
sed -n '1,140p' ffbuild/config.mak
make -j"$(nproc)"
make install
ff="$prefix/bin/ffmpeg.exe"
fp="$prefix/bin/ffprobe.exe"
test -s "$ff" && test -s "$fp"
"$ff" -hide_banner -filters > "$prefix/filters.txt"
"$ff" -hide_banner -encoders > "$prefix/encoders.txt"
"$ff" -hide_banner -hwaccels > "$prefix/hwaccels.txt"
"$ff" -hide_banner -buildconf > "$prefix/buildconf.txt" 2>&1
"$ff" -version > "$prefix/version.txt" 2>&1
git rev-parse HEAD > "$prefix/upstream-commit.txt"
printf 'Channel: %s\nUpstream branch: %s\n' "$channel" "$(git branch --show-current)" > "$prefix/build-info.txt"
for name in fruc_vulkan libplacebo bwdif_cuda bwdif_vulkan; do
    if ! grep -Eq "[[:space:]]${name}[[:space:]]" "$prefix/filters.txt"; then
        echo "ERROR: required filter missing: $name" >&2
        exit 1
    fi
done
for name in libsvtav1 libx264 libx265 hevc_nvenc av1_nvenc h264_nvenc; do
    if ! grep -Eq "[[:space:]]${name}[[:space:]]" "$prefix/encoders.txt"; then
        echo "ERROR: required encoder missing: $name" >&2
        exit 1
    fi
done
for name in vulkan cuda; do
    if ! grep -qx "$name" "$prefix/hwaccels.txt"; then
        echo "ERROR: required hardware acceleration missing: $name" >&2
        exit 1
    fi
done
"$ff" -hide_banner -loglevel error -f lavfi -i "testsrc2=s=128x72:r=24" \
    -frames:v 6 -c:v libx264 -f null -
echo "Build and component checks PASS for $channel"
