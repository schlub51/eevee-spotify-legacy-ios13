# Eevee Spotify Legacy iOS 13

Public archival repo for the iOS 13 / Spotify 8.8.2 compatibility work done on an older iPhone.

The practical goal was simple: make an otherwise barely usable legacy phone useful again as a music device. Current Spotify releases no longer support that iOS version, and the older app needed a compatibility tweak to recover a clean, usable listening experience.

## What Is Included

- The Theos tweak source: `Tweak.x`
- Theos packaging files: `Makefile`, `control`, `0Eevee.plist`
- Technical notes: `docs/technical-notes.md`
- IPA assembly notes: `docs/ipa-assembly.md`
- Rebuild helpers in `scripts/`

## What Is Not Included

This repo intentionally does not track Spotify IPAs, decrypted app bundles, compiled dylibs, `.deb` packages, or other proprietary/heavy artifacts. Those stay local only.

No IPA is published here because an IPA would include Spotify's proprietary application bundle. The repo is source-only so people can inspect the tweak and build against their own locally obtained compatible app copy.

See `DISCLAIMER.md` for affiliation, warranty, third-party component, and responsibility disclaimers.

## Build The Tweak

```sh
./scripts/build-tweak.sh
```

The project targets arm64, iOS 13.0 minimum, and the Theos iPhoneOS 16.5 SDK to avoid the iOS 13 loader issues observed with newer SDK output.

The repo lives under `New project`, whose path contains a space. Theos refuses to build from paths with spaces, so `scripts/build-tweak.sh` mirrors the source into `/tmp/eevee-spotify-legacy-ios13-build` before running `make package`.

## Current Status

The source targets Spotify 8.8.2 because that was the latest compatible version offered by the App Store on the iOS 13 device used for testing.

The tracked source is the latest local tweak snapshot from the session. It includes the v58 product-state work and the later lyrics/fullscreen fixes.

Compatibility with other Spotify versions or other iOS releases has not been validated. iOS 13.x with Spotify 8.8.2 is the known target.

Remaining technical notes are tracked in `docs/technical-notes.md`.

## Credits

This is a vibe-coded, AI-assisted compatibility experiment. The implementation was built through iterative testing on a real iOS 13 device, with the user directing the work and AI coding assistants helping inspect symbols, adjust hooks, build packages, and assemble the local test IPA.

Technical inspiration and ecosystem credits:

- Whoeevee / EeveeSpotify, for the modern EeveeSpotify project and the key free-tier resolver approach this experiment learned from.
- julioverne / Spotilife, for the original Spotilife lineage and older Spotify tweak work.
- Theos Team, for the iOS tweak build system.
- LRCLIB, for the public lyrics API used by the replacement lyrics view.
- CydiaSubstrate / Substitute ecosystem, for runtime tweak injection support on jailbroken devices.

## Disclaimer

We are not affiliated, associated, authorized, endorsed by, or in any way officially connected with any other company, agency, or government agency. All product and company names are trademarks(tm) or registered(r) trademarks of their respective holders. Use of them does not imply any affiliation with or endorsement by them.

The software is provided "as is," without any warranties, whether express or implied, including but not limited to warranties of merchantability or fitness for a particular purpose. The developers make no guarantees regarding the software's performance, reliability, or accuracy. In no event shall the developers be held liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or its use. Use of this software is at your own risk.

Furthermore, the software may utilize or depend on third-party software, libraries, or services. The developers are not liable for any issues, errors, or damages resulting from the use of such third-party components. The providers of those components are likewise not responsible for any liabilities arising from their use in this software.

By using this software, you acknowledge and accept full responsibility for any risks associated with its use.
