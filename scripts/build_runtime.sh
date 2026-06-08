#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FFMPEG="${SOURCE_FFMPEG:-/opt/homebrew/bin/ffmpeg}"
SOURCE_FFPROBE="${SOURCE_FFPROBE:-/opt/homebrew/bin/ffprobe}"
RUNTIME_DIR="${RUNTIME_DIR:-$ROOT_DIR/build/runtime/ffmpeg}"
BIN_DIR="$RUNTIME_DIR/bin"
LIB_DIR="$RUNTIME_DIR/lib"
LICENSE_DIR="$RUNTIME_DIR/LICENSES"

if [[ ! -x "$SOURCE_FFMPEG" ]]; then
  echo "Missing executable: $SOURCE_FFMPEG" >&2
  exit 1
fi

if [[ ! -x "$SOURCE_FFPROBE" ]]; then
  echo "Missing executable: $SOURCE_FFPROBE" >&2
  exit 1
fi

rm -rf "$RUNTIME_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR" "$LICENSE_DIR"

copy_binary() {
  local source="$1"
  local target="$2"
  cp "$source" "$target"
  chmod +x "$target"
}

is_homebrew_dependency() {
  [[ "$1" == /opt/homebrew/* || "$1" == /usr/local/Cellar/* || "$1" == /usr/local/opt/* ]]
}

resolve_dependency() {
  local dependency="$1"
  if is_homebrew_dependency "$dependency"; then
    echo "$dependency"
    return 0
  fi

  case "$dependency" in
    @rpath/*|@loader_path/*)
      local name
      name="$(basename "$dependency")"
      find /opt/homebrew/Cellar /opt/homebrew/opt /usr/local/Cellar /usr/local/opt \
        -name "$name" \( -type f -o -type l \) -print 2>/dev/null \
        | head -n 1 \
        | while read -r match; do realpath "$match"; done || true
      ;;
  esac
}

dependencies_for() {
  otool -L "$1" \
    | awk 'NR > 1 {print $1}' \
    | while read -r dependency; do
        resolved="$(resolve_dependency "$dependency" || true)"
        if [[ -n "$resolved" ]]; then
          echo "$resolved"
        fi
      done
}

copy_binary "$SOURCE_FFMPEG" "$BIN_DIR/ffmpeg"
copy_binary "$SOURCE_FFPROBE" "$BIN_DIR/ffprobe"

queue_file="$(mktemp /tmp/mediaforge-runtime-queue.XXXXXX)"
seen_file="$(mktemp /tmp/mediaforge-runtime-seen.XXXXXX)"
trap 'rm -f "$queue_file" "$seen_file"' EXIT

dependencies_for "$BIN_DIR/ffmpeg" >> "$queue_file"
dependencies_for "$BIN_DIR/ffprobe" >> "$queue_file"

while [[ -s "$queue_file" ]]; do
  dependency="$(head -n 1 "$queue_file")"
  tail -n +2 "$queue_file" > "$queue_file.next"
  mv "$queue_file.next" "$queue_file"

  if grep -Fxq "$dependency" "$seen_file"; then
    continue
  fi
  echo "$dependency" >> "$seen_file"

  if [[ ! -f "$dependency" ]]; then
    echo "Warning: dependency not found: $dependency" >&2
    continue
  fi

  copied="$LIB_DIR/$(basename "$dependency")"
  if [[ ! -f "$copied" ]]; then
    cp "$dependency" "$copied"
    chmod u+w "$copied"
  fi

  dependencies_for "$copied" >> "$queue_file"
done

rewrite_macho() {
  local file="$1"
  local rpath="$2"

  chmod u+w "$file"

  if [[ "$(basename "$file")" == *.dylib ]]; then
    install_name_tool -id "@rpath/$(basename "$file")" "$file" 2>/dev/null || true
  fi

  while read -r dependency; do
    install_name_tool -change "$dependency" "@rpath/$(basename "$dependency")" "$file" 2>/dev/null
  done < <(dependencies_for "$file")

  if ! otool -l "$file" | grep -Fq "$rpath"; then
    install_name_tool -add_rpath "$rpath" "$file" 2>/dev/null || true
  fi
}

rewrite_macho "$BIN_DIR/ffmpeg" "@executable_path/../lib"
rewrite_macho "$BIN_DIR/ffprobe" "@executable_path/../lib"

for dylib in "$LIB_DIR"/*.dylib; do
  [[ -e "$dylib" ]] || continue
  rewrite_macho "$dylib" "@loader_path"
done

if command -v codesign >/dev/null 2>&1; then
  for dylib in "$LIB_DIR"/*.dylib; do
    [[ -e "$dylib" ]] || continue
    codesign --force --sign - "$dylib" >/dev/null 2>&1
  done
  codesign --force --sign - "$BIN_DIR/ffmpeg" >/dev/null 2>&1
  codesign --force --sign - "$BIN_DIR/ffprobe" >/dev/null 2>&1
fi

ffmpeg_cellar="$(realpath "$SOURCE_FFMPEG" | sed -E 's#(/opt/homebrew/Cellar/ffmpeg/[^/]+).*#\1#')"
if [[ -d "$ffmpeg_cellar" ]]; then
  for license in LICENSE.md COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv2.1 COPYING.LGPLv3 README.md sbom.spdx.json INSTALL_RECEIPT.json; do
    if [[ -f "$ffmpeg_cellar/$license" ]]; then
      cp "$ffmpeg_cellar/$license" "$LICENSE_DIR/$license"
    fi
  done
fi

cat > "$LICENSE_DIR/SOURCE-OFFER.txt" <<'TEXT'
This app bundles FFmpeg binaries and their runtime libraries for local media conversion.

FFmpeg source code and licensing information:
https://ffmpeg.org/download.html
https://ffmpeg.org/legal.html

The bundled FFmpeg runtime in this package was assembled from the local Homebrew
ffmpeg installation used by the package builder. Homebrew formula metadata:
https://formulae.brew.sh/formula/ffmpeg
TEXT

echo "Built runtime at $RUNTIME_DIR"
du -sh "$RUNTIME_DIR" | awk '{print "Runtime size: " $1}'
