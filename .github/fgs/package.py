#!/usr/bin/env python3
"""Collect FFmpeg and recursively required non-system UCRT64 DLLs."""
import argparse
from collections import deque
from pathlib import Path
import re
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--prefix", type=Path, required=True)
parser.add_argument("--out", type=Path, required=True)
parser.add_argument("--msys-bin", type=Path, default=Path("C:/msys64/ucrt64/bin"))
args = parser.parse_args()
src = args.prefix.resolve()
out = args.out.resolve()
out.mkdir(parents=True, exist_ok=True)
msys_bin = args.msys_bin.resolve()
objdump = msys_bin / "objdump.exe"
if not objdump.is_file():
    raise SystemExit(f"objdump not found: {objdump}")

def indexed(directory):
    if not directory.is_dir():
        return {}
    return {p.name.casefold(): p for p in directory.iterdir() if p.is_file()}

for file in (src / "bin").iterdir():
    if file.suffix.casefold() in (".exe", ".dll"):
        shutil.copy2(file, out / file.name)

for filename in (
    "filters.txt", "encoders.txt", "hwaccels.txt", "buildconf.txt",
    "version.txt", "upstream-commit.txt", "build-info.txt",
):
    shutil.copy2(src / filename, out / filename)

for filename in ("COPYING.GPLv3", "COPYING.LGPLv3", "LICENSE.md"):
    path = Path("ffmpeg-src") / filename
    if path.is_file():
        shutil.copy2(path, out / filename)

if not (out / "ffmpeg.exe").is_file() or not (out / "ffprobe.exe").is_file():
    raise SystemExit("ffmpeg.exe / ffprobe.exe missing from package")

available = indexed(msys_bin)
system = indexed(Path("C:/Windows/System32"))
queue = deque([p for p in out.iterdir() if p.suffix.casefold() in (".exe", ".dll")])
done = set()
pattern = re.compile(r"^\s*DLL Name:\s*(\S+)", re.MULTILINE)

while queue:
    binary = queue.popleft()
    key = binary.name.casefold()
    if key in done:
        continue
    done.add(key)
    raw = subprocess.run(
        [str(objdump), "-p", str(binary)],
        check=True, capture_output=True, text=True, errors="replace"
    ).stdout
    for dll in pattern.findall(raw):
        name = dll.casefold()
        if name in indexed(out):
            continue
        if name in available:
            source = available[name]
            target = out / source.name
            shutil.copy2(source, target)
            queue.append(target)
        elif name in system or name.startswith(("api-ms-win-", "ext-ms-win-")):
            continue
        else:
            raise SystemExit(f"UNRESOLVED DLL: {dll}, imported by {binary.name}")
print(f"Portable Windows bundle: {out}, files: {len(list(out.iterdir()))}")
