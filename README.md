# Eevee Spotify Legacy iOS 13

Private archival repo for the iOS 13 / Spotify 8.8.2 compatibility work done on an older iPhone.

The practical goal was simple: make an otherwise barely usable legacy phone useful again as a music device. Current Spotify releases no longer support that iOS version, and the older app needed a compatibility tweak to recover a clean, usable listening experience.

## What Is Included

- The Theos tweak source: `Tweak.x`
- Theos packaging files: `Makefile`, `control`, `0Eevee.plist`
- A technical progress review: `docs/progress-review.md`
- IPA assembly notes: `docs/ipa-assembly.md`
- Rebuild helpers in `scripts/`

## What Is Not Included

This repo intentionally does not track Spotify IPAs, decrypted app bundles, compiled dylibs, `.deb` packages, or other proprietary/heavy artifacts. Those stay local only.

See `DISCLAIMER.md` for affiliation, warranty, third-party component, and responsibility disclaimers.

Known local artifacts from the original session:

- Final IPA: `/Users/nono/Downloads/Spotify-EeveeLegacy-8.8.2.ipa`
- Theos project source: `/tmp/eevee-ios13`
- IPA assembly workspace: `/tmp/eevee-ipa`

## Build The Tweak

```sh
./scripts/build-tweak.sh
```

The project targets arm64, iOS 13.0 minimum, and the Theos iPhoneOS 16.5 SDK to avoid the iOS 13 loader issues observed with newer SDK output.

The repo lives under `New project`, whose path contains a space. Theos refuses to build from paths with spaces, so `scripts/build-tweak.sh` mirrors the source into `/tmp/eevee-spotify-legacy-ios13-build` before running `make package`.

## Current Status

The last working source snapshot is v83. It was tested by pushing the dylib into the installed app and then used to build a standalone IPA named `Spotify-EeveeLegacy-8.8.2.ipa`.

Remaining notes are tracked in `docs/progress-review.md`.
