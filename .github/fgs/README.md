# FGS FFmpeg Windows x64 builds

This fork tracks **official FFmpeg** sources, without SVT-AV1-HDR.

- **Master:** upstream `FFmpeg/FFmpeg` branch `master`.
- **Stable:** upstream `FFmpeg/FFmpeg` branch `release/9.1`.
- Both apply `.github/fgs/host-image-copy.patch` (an opt-in Vulkan/CUDA interop workaround verified on RTX 4080).
- Workflow: `.github/workflows/fgs-ffmpeg-windows.yml`.
- Native Windows/MSYS2 UCRT64 runners. Run manually, on build-recipe changes, or each Sunday at 22:00 UTC.
- Artifact includes Windows binaries, recursively required DLLs, version/build reports and upstream commit ID.

CI fails if fruc_vulkan, libplacebo, bwdif_cuda, bwdif_vulkan, libsvtav1, NVENC, CUDA or Vulkan support is missing. It also performs a CPU encode smoke test.

To build on demand: open Actions > FGS FFmpeg Windows x64 > Run workflow. Download both artifacts once the jobs pass.

**GPU validation:** hosted CI has no RTX 4080. Test actual Vulkan/CUDA border, HDR/HLG and FGS integration on the user's GPU before replacing existing production FFmpeg.

**FGS usage:** the patched binary accepts device option `disable_host_image_copy=1` in addition to `disable_multiplane=1`. Unpatched Gyan FFmpeg does not accept the new option. FGS itself is not modified by this repository.

No new branches, PRs or application release are made.
