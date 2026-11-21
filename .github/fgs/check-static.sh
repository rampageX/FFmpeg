#!/usr/bin/env bash
set -euo pipefail

: "${CHANNEL:?Missing CHANNEL}"
: "${ARTIFACT_DIR:?Missing ARTIFACT_DIR}"
: "${SOURCE_REF:?Missing SOURCE_REF}"

mkdir -p unpack
mapfile -t archives < <(find "$ARTIFACT_DIR" -maxdepth 1 -type f -name '*.zip')
test "${#archives[@]}" -eq 1 || { echo "Expected one static ZIP" >&2; exit 1; }
unzip -q "${archives[0]}" -d unpack

ff="$(find unpack -type f -name ffmpeg.exe -print -quit)"
fp="$(find unpack -type f -name ffprobe.exe -print -quit)"
test -n "$ff" && test -n "$fp" || { echo "Missing ffmpeg / ffprobe" >&2; exit 1; }
file "$ff" | grep -q 'PE32+' || { echo "Not Windows x64 PE" >&2; exit 1; }
test -z "$(find unpack -type f -iname '*.dll' -print -quit)" || { echo "Unexpected DLLs" >&2; exit 1; }

for exe in "$ff" "$fp"; do
    imports="/tmp/$(basename "$exe").imports"
    x86_64-w64-mingw32-objdump -p "$exe" > "$imports"
    if grep -Ei 'DLL Name: (avcodec|avutil|avformat|swscale|swresample|lib[^ ]+\.dll)' "$imports"; then
        echo "Third-party DLL dependency detected: $exe" >&2
        exit 1
    fi
done

# Wine enumerates compiled-in capabilities without needing a physical GPU.
root="$(pwd -P)"
ff_path="/test/${ff#unpack/}"
fp_path="/test/${fp#unpack/}"
docker run --rm -e WINEDEBUG=-all -v "$root/unpack":/test:ro \
    ghcr.io/ffmpeg-builds/ffmpeg-builds/win64-gpl:latest \
    bash -c '
      set -e
      wine "$1" -hide_banner -filters > /tmp/fgs-filters.txt
      wine "$1" -hide_banner -encoders > /tmp/fgs-encoders.txt
      wine "$2" -version > /dev/null
      wine "$1" -version > /tmp/fgs-version.txt
      if [ "$3" = "Stable" ]; then
          grep -Eq "^ffmpeg version 9[.]1[.]git-FGS-[0-9a-f]+-[0-9]{8}" /tmp/fgs-version.txt ||
              { echo "Missing Stable 9.1.git branch version identifier" >&2; exit 1; }
      fi
      for name in fruc_vulkan libplacebo bwdif_cuda bwdif_vulkan; do
          grep -Eq "[[:space:]]${name}[[:space:]]" /tmp/fgs-filters.txt || { echo "Missing filter: $name" >&2; exit 1; }
      done
      for name in libsvtav1 libx264 libx265 hevc_nvenc av1_nvenc h264_nvenc; do
          grep -Eq "[[:space:]]${name}[[:space:]]" /tmp/fgs-encoders.txt || { echo "Missing encoder: $name" >&2; exit 1; }
      done
      echo "Static executable and FGS codec/filter checks passed"
    ' _ "$ff_path" "$fp_path" "$CHANNEL"

out="FGS-FFmpeg-${CHANNEL}-Windows-x64-Static.zip"
mv "${archives[0]}" "$out"
printf 'Channel: %s\nUpstream ref: %s\nStatic dependency base: FFmpeg-Builds/FFmpeg-Builds (official SVT-AV1)\nPatch: disable_host_image_copy=1\n' \
    "$CHANNEL" "$SOURCE_REF" > "FGS-FFmpeg-${CHANNEL}-BUILD.txt"
sha256sum "$out" > "$out.sha256"
