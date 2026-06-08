# FFmpeg 0.1.3

Bundled runtime release.

## Added

- Bundled FFmpeg / FFprobe runtime inside the macOS app package
- Runtime packaging script that collects linked Homebrew dylibs and rewrites them to app-relative `@rpath` references
- App runtime lookup now prefers `Contents/Resources/Runtime/ffmpeg/bin` before system or Homebrew paths
- Bundled FFmpeg license files and source-offer note

## Notes

- Users no longer need Homebrew or a preinstalled FFmpeg runtime for normal use.
- The Homebrew install assistant remains as a fallback if the bundled runtime is removed or unavailable.
- The bundled runtime is assembled from the builder Mac's Homebrew FFmpeg and is GPL-enabled because the selected FFmpeg build includes GPL codecs such as x264/x265.

# FFmpeg 0.1.2

One-click runtime install release.

## Added

- In-app Homebrew + FFmpeg installation flow
- Stage progress bar for runtime setup
- Single-line live installer status
- Automatic `ffmpeg` / `ffprobe` verification after install

## Notes

- If Homebrew is missing on Apple Silicon, the app may ask macOS for administrator authentication to prepare `/opt/homebrew`.
- Homebrew and FFmpeg installation still require network access.
- Xcode Command Line Tools prompts may still appear on clean macOS systems because Apple controls that installation flow.

# FFmpeg 0.1.1

Runtime setup release.

## Added

- Startup detection for missing FFmpeg / FFprobe runtime
- Runtime assistant sheet when the target Mac has no FFmpeg environment
- Homebrew Terminal installer for `brew install ffmpeg`
- Runtime disk space estimate in the app UI

## Notes

- The installer does not silently download executable code. It opens a Terminal installer so the user can see and approve the Homebrew command.
- Homebrew is still required for the one-click runtime installer. If Homebrew is missing, the app links to `https://brew.sh`.
- Suggested free disk space is at least 1GB for FFmpeg plus dependencies and cache.

# FFmpeg 0.1.0

Initial lightweight macOS release.

## Included

- SwiftUI native macOS interface
- Drag-and-drop file import
- Video-to-audio, video-to-video, and audio-to-audio conversion
- Serial batch queue
- Preset-based conversion
- Advanced parameters for common audio/video settings
- Progress display with percentage during active conversion
- Natural-language error summaries
- Full FFmpeg log preservation
- Chinese / English UI switch
- Apple Silicon DMG packaging script
- Apple Silicon PKG installer script
- Custom app icon from the bundled image

## Known Notes

- Requires Homebrew FFmpeg on the target Mac.
- This build is ad-hoc signed, not notarized.
- First launch on another Mac may require right-click Open.
- Non-App-Store installs generally uninstall from Finder, not Launchpad long-press delete.
