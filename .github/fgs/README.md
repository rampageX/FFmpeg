# FGS FFmpeg Windows x64 static builds

This fork builds portable **static Windows x64** FFmpeg from official FFmpeg source, with an opt-in RTX 4080-tested Vulkan/CUDA interoperability workaround. **Stable** retains official SVT-AV1. **Master/Nightly** uses the SVT-AV1-HDR fork so FGS can obtain both programs from our own Releases. No FFmpeg DLL package.

## Upstream static build foundation

- The build and dependency recipe is pinned to [FFmpeg-Builds/FFmpeg-Builds](https://github.com/FFmpeg-Builds/FFmpeg-Builds) commit `7f2a6b1050d302144de8366afa37a75e46f326aa`.
- **Stable:** original `FFmpeg-Builds/FFmpeg-Builds` static MinGW image and pinned builder, with official `AOMediaCodec/SVT-AV1`. This recipe is unchanged.
- **Master/Nightly:** pinned `QuickFatHedgehog/FFmpeg-Builds-SVT-AV1-HDR` builder and its `win64-gpl` dependency image. The recipe pins `juliobbv-p/svt-av1-hdr` at `0ce7e13af2396bf3bf06408a09f1138f82b01b28`. Actual linkage is checked by a 10-bit encode using `hbd-mds=1:film-grain=0:tune=6` and the `SVT-AV1-HDR` encoder banner.
- `.github/fgs/prepare-builder.py` remains the Stable adaptation. `.github/fgs/prepare-master-hdr.py` requires the same host-copy patch in the Master builder; an absent or rejected patch fails the build. Dependency Docker images are reused; only FFmpeg is compiled in our own workflow.
- Master uses official FFmpeg `master`; Stable uses official `release/9.1`.
- Stable reports `9.1.git-FGS-<upstream SHA>-<build date>` in `ffmpeg -version`. The `.git` suffix is intentional: this is the official release branch snapshot, not a tagged 9.1 source release. Master retains the upstream `N-...` identifier.
- Both use the original verified patch `.github/fgs/host-image-copy.patch`, adding Vulkan option `disable_host_image_copy=1` (default unchanged).

## Build and checks

Open **Actions > FGS FFmpeg Static Windows x64 > Run workflow** for a manual build. Build jobs run after recipe changes or daily at 03:17 UTC, pulling current official `master` and `release/9.1` source. When **both** scheduled builds pass, a new `nightly-YYYYMMDD` GitHub prerelease is published with the two Windows x64 static ZIPs; failed builds never publish. Re-running the same day never overwrites an existing Nightly. The official `fgs-YYYY.MM.DD` release remains separate. No upstream force-sync is performed on the fork's `master`.

Build host is Linux because the established FFmpeg-Builds toolchain **cross-compiles Windows binaries**. Only Windows executable files are released. This is an FFmpeg build workflow, not an FGS application Release or BAT packager.

CI fails if the patch does not apply, if FFmpeg/FFprobe are absent, if the Windows binary imports third-party runtime DLLs, or if Wine enumeration cannot find required fruc_vulkan, libplacebo, CUDA/BWDIF, NVENC and libx264/x265 encoders. Master also must pass the actual SVT-AV1-HDR 10-bit fork encode probe; Stable stays on official SVT-AV1.

Target RTX 4080 hardware validation is still required before replacing the stable FFmpeg used by FGS. An unpatched Gyan binary will not understand the new device option.

No extra Git branches, upstream PRs, or FGS app changes are made.
