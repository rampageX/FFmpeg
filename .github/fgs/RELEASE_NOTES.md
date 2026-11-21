# FGS FFmpeg Windows x64 · Stable 9.1 + Master

Windows x64 **static** builds based on original FFmpeg, produced by the established `FFmpeg-Builds/FFmpeg-Builds` static MinGW toolchain.

- **Stable:** `9.1.git-FGS-47b92841e33b-20261121`, official `release/9.1` source.
- **Master:** `N-129181-gb8c699bfbe-20261121`, official `master` source.
- **Patch:** opt-in Vulkan/CUDA host-image-copy workaround (`disable_host_image_copy=1`) verified with Film Grain Studio's GPU film borders.
- **Includes:** FFmpeg and FFprobe, `fruc_vulkan`, `libplacebo`, Vulkan/CUDA, NVENC and official SVT-AV1. No SVT-AV1-HDR fork.
- **Validation:** both static Windows ZIPs passed CI filter/encoder checks, Windows PE import checks and Wine capability inspection. Stable 9.1 completed RTX 4080 PQ/HLG GPU-border and SVP/AI tests; SVT/AV1 also passed user verification.
- **Artifacts:** one Stable ZIP and one Master ZIP; neither requires codec DLLs or an MSYS2 installation.

Upstream FFmpeg development branches are fetched directly during each build. The `rampageX/FFmpeg` Git `master` is not overwritten by upstream. Separate daily Nightly prereleases start after their scheduled CI builds pass.
