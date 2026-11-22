#!/usr/bin/env python3
"""Adapt pinned QuickFat SVT-AV1-HDR static Win64 recipe; require FGS patch."""
from pathlib import Path

root = Path("builder")
build = root / "build.sh"
s = build.read_text(encoding="utf-8")
old = r'''    if [ -f "/patches/ffmpeg/\$BRANCH_NAME.patch" ]; then
        git apply "/patches/ffmpeg/\$BRANCH_NAME.patch"
    fi'''
new = r'''    test -f "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git apply --check "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git apply "/patches/ffmpeg/\$BRANCH_NAME.patch"
    git diff --check'''
assert s.count(old) == 1, "QuickFat patch-injection anchor changed"
s = s.replace(old, new, 1)
build.write_text(s, encoding="utf-8")

vars_sh = root / "util/vars.sh"
v = vars_sh.read_text(encoding="utf-8")
old = 'REPO="${GITHUB_REPOSITORY:-ffmpeg-builds/ffmpeg-builds}"'
assert v.count(old) == 1, "QuickFat image registry selector changed"
v = v.replace(old, 'REPO="quickfathedgehog/ffmpeg-builds-svt-av1-hdr"', 1)
vars_sh.write_text(v, encoding="utf-8")

svt = (root / "scripts.d/50-svtav1.sh").read_text(encoding="utf-8")
assert 'SCRIPT_REPO="https://github.com/juliobbv-p/svt-av1-hdr.git"' in svt, "Missing SVT-AV1-HDR fork"
assert 'SCRIPT_COMMIT="0ce7e13af2396bf3bf06408a09f1138f82b01b28"' in svt, "Unverified SVT-AV1-HDR dependency"
patch = Path(".github/fgs/host-image-copy.patch").read_bytes()
assert patch.endswith(b"\n")
target = root / "patches/ffmpeg/master.patch"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(patch)
assert "GIT_BRANCH_OVERRIDE" in s and "FFMPEG_REPO_OVERRIDE" in s
assert "quickfathedgehog/ffmpeg-builds-svt-av1-hdr" in vars_sh.read_text(encoding="utf-8")
print("Ready: official FFmpeg master, pinned SVT-AV1-HDR dependency image, mandatory FGS Vulkan/CUDA patch")
