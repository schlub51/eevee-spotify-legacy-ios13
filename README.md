# Eevee Spotify Legacy iOS 13

Small Theos tweak experiment for Spotify 8.8.2 on iOS 13.

I made this because an old iPhone was still useful as a music device, and Spotify 8.8.2 was the newest version the App Store would offer on that phone.

## Included

- The Theos tweak source: `Tweak.x`
- Theos packaging files: `Makefile`, `control`, `0Eevee.plist`
- Technical notes: `docs/technical-notes.md`
- Install/build guide: `docs/install.md`
- IPA assembly notes: `docs/ipa-assembly.md`
- Rebuild helpers in `scripts/`

## Not Included

No IPA or app bundle is included.

GitHub releases may include a compiled `.deb` for jailbroken devices. The repo itself keeps generated packages out of Git.

See `DISCLAIMER.md` for affiliation, warranty, third-party component, and responsibility disclaimers.

## Build The Tweak

See `docs/install.md` for the full flow.

If you just want to test it on a jailbroken iOS 13 device, check the latest GitHub release first.

```sh
./scripts/build-tweak.sh
```

The project targets arm64 and iOS 13.0+.

The build helper mirrors the source into `/tmp` first because Theos does not like project paths with spaces.

## Current Status

Known target: iOS 13.x + Spotify 8.8.2.

The tracked source is the latest local snapshot, including the product-state work and later lyrics/fullscreen fixes.

Other iOS or Spotify versions are untested.

## Credits

This is a vibe-coded, AI-assisted compatibility experiment, tested iteratively on a real iOS 13 device.

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
