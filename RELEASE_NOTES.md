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
