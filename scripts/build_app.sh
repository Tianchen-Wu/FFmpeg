#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/FFmpeg.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
RUNTIME_SOURCE_DIR="$ROOT_DIR/build/runtime/ffmpeg"
BUNDLE_FFMPEG_RUNTIME="${BUNDLE_FFMPEG_RUNTIME:-1}"

cd "$ROOT_DIR"
mkdir -p "$ROOT_DIR/.build/caches/home" "$ROOT_DIR/.build/caches/clang" "$ROOT_DIR/.build/caches/swiftpm"
HOME="$ROOT_DIR/.build/caches/home" \
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/caches/clang" \
swift build --disable-sandbox --cache-path "$ROOT_DIR/.build/caches/swiftpm" -c release --product MediaForge

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/MediaForge" "$MACOS_DIR/MediaForge"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
if [[ "$BUNDLE_FFMPEG_RUNTIME" == "1" ]]; then
  "$ROOT_DIR/scripts/build_runtime.sh"
  mkdir -p "$RESOURCES_DIR/Runtime"
  ditto "$RUNTIME_SOURCE_DIR" "$RESOURCES_DIR/Runtime/ffmpeg"
fi
chmod +x "$MACOS_DIR/MediaForge"

echo "Built $APP_DIR"
