# FGS FFmpeg Windows x64 static builds

This fork builds portable **static Windows x64** FFmpeg from the official FFmpeg source, with an opt-in RTX 4080-tested Vulkan/CUDA interoperability workaround. No SVT-AV1-HDR fork and no FFmpeg DLL package.

## Upstream static build foundation

- The build and dependency recipe is pinned to [FFmpeg-Builds/FFmpeg-Builds](https://github.com/FFmpeg-Builds/FFmpeg-Builds) commit `7f2a6b1050d302144de8366afa37a75e46f326aa`.
- Only `win64-gpl` is built. This is the original upstream static MinGW cross-compilation image with stock `AOMediaCodec/SVT-AV1`, not the SVT-AV1-HDR branch.
- `.github/fgs/prepare-builder.py` ports the small patch-injection mechanism used by QuickFatHedgehog's FFmpeg-Builds fork into the original static build script. It does not rebuild the upstream image.
- Master uses official FFmpeg `master`; Stable uses official `release/9.1`.
- Both use the original verified patch `.github/fgs/host-image-copy.patch`, adding Vulkan option `disable_host_image_copy=1` (default unchanged).

## Build and checks

Open **Actions > FGS FFmpeg Static Windows x64 > Run workflow**. The workflow also triggers for recipe changes and weekly. Each run produces independent Master/Stable Windows x64 portable static ZIP artifacts.

Build host is Linux because the established FFmpeg-Builds toolchain **cross-compiles Windows binaries**. Only Windows executable files are released. This is an FFmpeg build workflow, not an FGS application Release or BAT packager.

CI fails if the patch does not apply, if FFmpeg/FFprobe are absent, if the Windows binary imports third-party runtime DLLs, or if Wine enumeration cannot find required fruc_vulkan, libplacebo, CUDA/BWDIF, NVENC, libx264/x265 and official SVT-AV1 support.

Target RTX 4080 hardware validation is still required before replacing the stable FFmpeg used by FGS. An unpatched Gyan binary will not understand the new device option.

No extra Git branches, upstream PRs, or FGS app changes are made.
