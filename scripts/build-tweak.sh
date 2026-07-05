#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEOS="${THEOS:-$HOME/theos}"
BUILD_ROOT="${BUILD_ROOT:-/tmp/eevee-spotify-legacy-ios13-build}"

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"
cp "$ROOT/Makefile" "$ROOT/control" "$ROOT/0Eevee.plist" "$ROOT/Tweak.x" "$BUILD_ROOT/"

cd "$BUILD_ROOT"
THEOS="$THEOS" make package

mkdir -p "$ROOT/packages"
cp -R "$BUILD_ROOT/packages/." "$ROOT/packages/"
echo "Packages copied to $ROOT/packages"
