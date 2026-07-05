#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 /path/to/base.ipa /path/to/0Eevee.dylib /path/to/output.ipa" >&2
  exit 2
fi

BASE_IPA="$1"
TWEAK_DYLIB="$2"
OUTPUT_IPA="$3"
WORKDIR="${WORKDIR:-/tmp/eevee-ipa-assemble}"
THEOS_SDK="${THEOS_SDK:-/Users/nono/theos/sdks/iPhoneOS16.5.sdk}"
LOAD_SLOT="${LOAD_SLOT:-Spotilife.dylib}"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cp "$BASE_IPA" "$WORKDIR/base.ipa"
unzip -q "$WORKDIR/base.ipa" -d "$WORKDIR/work"

APP="$WORKDIR/work/Payload/Spotify.app"
FW="$APP/Frameworks"

xcrun --sdk iphoneos clang -isysroot "$THEOS_SDK" -arch arm64 -dynamiclib -miphoneos-version-min=13.0 \
  -o "$WORKDIR/stub16.dylib" -x c /dev/null

cp "$TWEAK_DYLIB" "$WORKDIR/$LOAD_SLOT"
install_name_tool -id "@executable_path/Frameworks/$LOAD_SLOT" "$WORKDIR/$LOAD_SLOT"
install_name_tool -change "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" \
  "@executable_path/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "$WORKDIR/$LOAD_SLOT"

cp "$WORKDIR/$LOAD_SLOT" "$FW/$LOAD_SLOT"
cp "$WORKDIR/stub16.dylib" "$FW/Sposify.dylib"
cp "$WORKDIR/stub16.dylib" "$FW/SposifyFix.dylib"

install_name_tool -id "@executable_path/Frameworks/Sposify.dylib" "$FW/Sposify.dylib"
install_name_tool -id "@executable_path/Frameworks/SposifyFix.dylib" "$FW/SposifyFix.dylib"

ldid -e "$APP/Spotify" > "$WORKDIR/ents.plist" 2>/dev/null || true
ldid -S "$FW/$LOAD_SLOT"
ldid -S "$FW/Sposify.dylib"
ldid -S "$FW/SposifyFix.dylib"
if [[ -s "$WORKDIR/ents.plist" ]]; then
  ldid -S"$WORKDIR/ents.plist" "$APP/Spotify"
else
  ldid -S "$APP/Spotify"
fi

(cd "$WORKDIR/work" && /usr/bin/zip -qr9 "$OUTPUT_IPA" Payload)

echo "Wrote $OUTPUT_IPA"
