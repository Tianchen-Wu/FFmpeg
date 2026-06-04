#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FFmpeg"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"
PKG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-arm64.pkg"

"$ROOT_DIR/scripts/build_app.sh"

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_PATH" 2>/dev/null || true
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_PATH"
fi

mkdir -p "$DIST_DIR"
COPYFILE_DISABLE=1 pkgbuild \
  --component "$APP_PATH" \
  --install-location /Applications \
  --identifier local.ffmpeg.mac.pkg \
  --version "$VERSION" \
  "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH" || true

echo "Built $PKG_PATH"
