# FFmpeg

Lightweight macOS GUI wrapper for local FFmpeg media conversion.

## Current Version

`0.1.0`

## Features

- Video to audio
- Video to video
- Audio to audio
- Serial batch conversion
- Presets for H.264, H.265, AV1, MP3, M4A, WAV, FLAC, Opus, and Whisper WAV
- Default output beside the source file
- Optional unified output folder
- Readable errors and saved FFmpeg logs
- Chinese / English UI switch

## Requirements

- Apple Silicon Mac
- macOS 13 Ventura or newer
- FFmpeg installed with Homebrew:

```bash
brew install ffmpeg
```

The app auto-detects:

- `/opt/homebrew/bin/ffmpeg`
- `/opt/homebrew/bin/ffprobe`

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
dist/FFmpeg-0.1.0-arm64.dmg
```

## Distribution Note

This MVP package is ad-hoc signed but not Apple notarized. On another Mac, Gatekeeper may require right-clicking the app and choosing Open on first launch. A future public distribution build should use Developer ID signing and Apple notarization.
