#!/usr/bin/env python3
"""Test-only: preserve the existing HDR recipe and pin the failing source."""
from pathlib import Path
import subprocess

subprocess.run(["python3", ".github/fgs/prepare-master-hdr.py"], check=True)
root = Path("builder")
build = root / "build.sh"
s = build.read_text(encoding="utf-8")
old = "    cd ffmpeg\n\n    BRANCH_NAME="
new = """    cd ffmpeg
    git checkout --detach 359c82515228774eb683dffce9d623b6b4a2fa53
    test "\$(git rev-parse HEAD)" = "359c82515228774eb683dffce9d623b6b4a2fa53"
    test "\$(git hash-object libavfilter/vf_overlay_vulkan.c)" = "602a88e87929fca754ac800d4c8425bb848b4440"

    BRANCH_NAME="""
# Escape substitutions for the shell-generated inner build script.
new = new.replace("$(", r"\$(")
assert s.count(old) == 1, "Pinned source checkout anchor changed"
s = s.replace(old, new, 1)
old = '    --extra-version="\\$(date +%Y%m%d)"'
assert s.count(old) == 1, "Version anchor changed"
s = s.replace(old, '    --extra-version="OVTB-K6M2-\\$(date +%Y%m%d)"', 1)
build.write_text(s, encoding="utf-8")
p = root / "patches/ffmpeg/master.patch"
p.write_bytes(p.read_bytes() + Path(".github/fgs/overlay-vulkan-timebase.patch").read_bytes())
