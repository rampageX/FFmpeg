#!/usr/bin/env python3
"""Adapt upstream FFmpeg-Builds static Win64 recipe with FGS patch injection."""
from pathlib import Path

root = Path("builder")
script = root / "build.sh"
s = script.read_text(encoding="utf-8")
old = "    cd ffmpeg\n\n    ./configure"
new = r"""    cd ffmpeg

    BRANCH_NAME=\$(basename '$GIT_BRANCH')
    test -f "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git apply --check "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git apply "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git diff --check

    # Keep master on Git revision identifiers. Stable snapshots retain the
    # official 9.1.git release-branch identity plus traceable commit SHA.
    if [ '$GIT_BRANCH' = 'release/9.1' ]; then
        release=\$(cat RELEASE)
        if [ "\$release" != "9.1.git" ]; then
            echo "Unexpected FFmpeg stable RELEASE: \$release" >&2
            exit 1
        fi
        printf '%s\n' "\$release-FGS-\$(git rev-parse --short=12 HEAD)" > FF_VERSION
    fi

    ./configure"""
assert s.count(old) == 1, "FFmpeg-Builds build.sh anchor changed"
s = s.replace(old, new, 1)
old = ' -v "$BUILD_SCRIPT":/build.sh "$IMAGE" bash /build.sh'
new = ' -v "$PWD/patches":/patches:ro -v "$BUILD_SCRIPT":/build.sh "$IMAGE" bash /build.sh'
assert s.count(old) == 1, "FFmpeg-Builds Docker invocation changed"
script.write_text(s.replace(old, new, 1), encoding="utf-8")

vars_sh = root / "util/vars.sh"
v = vars_sh.read_text(encoding="utf-8")
old = 'REPO="${GITHUB_REPOSITORY:-ffmpeg-builds/ffmpeg-builds}"'
assert v.count(old) == 1, "FFmpeg-Builds image selector changed"
vars_sh.write_text(v.replace(old, 'REPO="ffmpeg-builds/ffmpeg-builds"', 1), encoding="utf-8")

patch_source = Path(".github/fgs/host-image-copy.patch").read_bytes()
assert patch_source.endswith(b"\n")
for name in ("master", "9.1"):
    target = root / "patches/ffmpeg" / (name + ".patch")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(patch_source)
svt = (root / "scripts.d/50-svtav1.sh").read_text(encoding="utf-8")
assert "https://github.com/AOMediaCodec/SVT-AV1.git" in svt, "Not official SVT-AV1"
assert "juliobbv-p" not in svt, "Unexpected SVT-AV1-HDR!"
print("Ready: official stock SVT-AV1, static win64-gpl, master/release-9.1 patch")
