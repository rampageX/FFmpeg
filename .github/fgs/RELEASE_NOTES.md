# FGS FFmpeg Windows x64 · Stable 9.1 + Master SVT-AV1-HDR

Official FFmpeg source, Windows x64 static executables, two separately verified channels. This release publishes the **user-accepted** Master SVT-AV1-HDR build without replacing the earlier 2026-11-22 release.

- **Stable:** official FFmpeg `release/9.1` plus original `AOMediaCodec/SVT-AV1`. Its pinned build recipe is unchanged.
- **Master:** official FFmpeg `master` plus `juliobbv-p/svt-av1-hdr` (pinned `0ce7e13af2396bf3bf06408a09f1138f82b01b28`), built with QuickFatHedgehog's pinned static dependency recipe.
- **Both:** FGS Vulkan/CUDA interoperability patch `disable_host_image_copy=1` (opt-in, no change to the default).
- **Included:** static `ffmpeg.exe`, `ffprobe.exe`, `fruc_vulkan`, `libplacebo`, Vulkan/CUDA, NVENC, libx264/libx265.
- **Validation:** Windows x64 PE and static DLL-import checks, compiled filter/encoder checks, and actual two-frame 10-bit `libsvtav1` encode with `hbd-mds=1:film-grain=0:tune=6` and the `SVT-AV1-HDR` banner. Windows CI build run: https://github.com/rampageX/FFmpeg/actions/runs/45021608480.
- **FGS:** user reports the new Master tested successfully with FGS. Configure the same Master `bin` directory as primary FFmpeg and enable "same as primary FFmpeg" for the optional special FFmpeg. SVT-HDR and FRUC can then use one executable.
- **Fallback:** Stable does **not** include SVT-AV1-HDR; switching only to Stable will disable FGS's SVT-HDR-specific CPU path.

Upstream FFmpeg `master` / `release/9.1` are fetched at build time; our repository `master` remains the build recipe, not a forced copy of upstream. Daily scheduled Nightly prereleases remain separate.
