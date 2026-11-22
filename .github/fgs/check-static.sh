#!/usr/bin/env bash
set -euo pipefail

: "${CHANNEL:?Missing CHANNEL}"
: "${ARTIFACT_DIR:?Missing ARTIFACT_DIR}"
: "${SOURCE_REF:?Missing SOURCE_REF}"

mkdir -p unpack
mapfile -t archives < <(find "$ARTIFACT_DIR" -maxdepth 1 -type f \( -name '*.zip' -o -name '*.7z' \))
test "${#archives[@]}" -eq 1 || { echo "Expected one static ZIP/7z" >&2; exit 1; }
if [[ "${archives[0]}" == *.7z ]]; then
    7z x -y -ounpack "${archives[0]}" >/dev/null
else
    unzip -q "${archives[0]}" -d unpack
fi

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
      if [ "$3" = "Master" ]; then
          # Same two-frame 10-bit HDR-fork parameters required by the FGS CPU path.
          wine "$1" -hide_banner -nostdin -v info -f lavfi -i testsrc2=size=64x64:rate=24 -frames:v 2 -an -pix_fmt yuv420p10le -c:v libsvtav1 -preset 12 -svtav1-params hbd-mds=1:film-grain=0:tune=6 -f null NUL > /tmp/fgs-hdr-probe.txt 2>&1 ||
              { cat /tmp/fgs-hdr-probe.txt; echo "SVT-AV1-HDR encoder probe failed" >&2; exit 1; }
          grep -q "SVT-AV1-HDR" /tmp/fgs-hdr-probe.txt ||
              { cat /tmp/fgs-hdr-probe.txt; echo "Master is not linked against SVT-AV1-HDR" >&2; exit 1; }
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
if [[ "${archives[0]}" == *.7z ]]; then
    (cd unpack && zip -q -r -9 "../$out" .)
else
    mv "${archives[0]}" "$out"
fi
if [[ "$CHANNEL" == "Master" ]]; then
    dependency="QuickFatHedgehog/FFmpeg-Builds-SVT-AV1-HDR (juliobbv-p/svt-av1-hdr@0ce7e13af2396bf3bf06408a09f1138f82b01b28)"
else
    dependency="FFmpeg-Builds/FFmpeg-Builds (official SVT-AV1)"
fi
printf 'Channel: %s\nUpstream ref: %s\nStatic dependency base: %s\nPatch: disable_host_image_copy=1\n' \
    "$CHANNEL" "$SOURCE_REF" "$dependency" > "FGS-FFmpeg-${CHANNEL}-BUILD.txt"
sha256sum "$out" > "$out.sha256"
