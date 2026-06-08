# FFmpeg

Lightweight macOS GUI wrapper for local FFmpeg media conversion.

## Current Version

`0.1.3`

## Features

- Video to audio
- Video to video
- Audio to audio
- Serial batch conversion
- Presets for H.264, H.265, AV1, MP3, M4A, WAV, FLAC, Opus, and Whisper WAV
- Default output beside the source file
- Optional unified output folder
- Readable errors and saved FFmpeg logs
- Startup FFmpeg runtime detection
- Bundled FFmpeg / FFprobe runtime for one-step installation
- In-app Homebrew + FFmpeg install assistant with progress
- Chinese / English UI switch

## Requirements

- Apple Silicon Mac
- macOS 13 Ventura or newer

Release packages include FFmpeg and FFprobe inside the app bundle. Users do not need to install Homebrew or FFmpeg before using the app.

The app auto-detects runtime paths in this order:

- `FFmpeg.app/Contents/Resources/Runtime/ffmpeg/bin/ffmpeg`
- `FFmpeg.app/Contents/Resources/Runtime/ffmpeg/bin/ffprobe`
- `/opt/homebrew/bin/ffmpeg`
- `/opt/homebrew/bin/ffprobe`

If every runtime source is missing, the app opens a runtime assistant as a fallback. The assistant can install Homebrew when needed, install FFmpeg through Homebrew, show a stage progress bar, and verify `ffmpeg` / `ffprobe` before conversion.

## Build Requirements

Packaging a release with bundled FFmpeg requires Homebrew FFmpeg on the build Mac:

```bash
brew install ffmpeg
```

## Build

```bash
scripts/build_app.sh
```

Output:

```text
build/FFmpeg.app
```

## Package DMG

```bash
scripts/package_dmg.sh
```

Output:

```text
dist/FFmpeg-0.1.3-arm64.dmg
```

## Package Installer

```bash
scripts/package_pkg.sh
```

Output:

```text
dist/FFmpeg-0.1.3-arm64.pkg
```

The `.pkg` installer places `FFmpeg.app` in `/Applications`.

## Distribution Note

This MVP package is ad-hoc signed but not Apple notarized. On another Mac, Gatekeeper may require right-clicking the app and choosing Open on first launch. A future public distribution build should use Developer ID signing and Apple notarization.

The app bundles FFmpeg binaries assembled from Homebrew FFmpeg on the build Mac. Bundled FFmpeg license files and source-offer notes are placed under `FFmpeg.app/Contents/Resources/Runtime/ffmpeg/LICENSES`.

Apps distributed outside the Mac App Store usually do not show the Launchpad long-press delete `x`. To uninstall, remove `FFmpeg.app` from `/Applications`.
