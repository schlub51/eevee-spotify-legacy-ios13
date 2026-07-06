# Install / Build Guide

This repo is meant for people who already have a compatible setup and want to build/test the tweak themselves.

Known tested setup:

- iPhone X
- iOS 13.x
- checkra1n-style jailbreak
- Spotify 8.8.2

Other devices, iOS versions, Spotify versions, and CarPlay are untested.

## Requirements

On the Mac:

- Theos
- Xcode command line tools
- `ldid`
- an iOS 16.5 Theos SDK, or another SDK that still produces binaries loadable on iOS 13

On the phone:

- jailbroken iOS 13.x device
- Substrate/Substitute-style tweak injection
- Spotify 8.8.2 installed

## Option 1: Build And Install The Deb

Build:

```sh
./scripts/build-tweak.sh
```

The package will be copied to:

```text
packages/
```

Install it on the phone using your usual jailbreak package flow, for example by copying the `.deb` to the device and installing it with `dpkg`.

Example:

```sh
scp packages/*.deb root@iphone:/tmp/
ssh root@iphone
dpkg -i /tmp/com.eevee.spotify.legacy_*.deb
killall -9 Spotify
```

Adjust the host/user/connection method to your setup.

## Option 2: Build A Local IPA

Use this only if you already have your own compatible Spotify 8.8.2 IPA and know how you obtained it.

First build the tweak:

```sh
./scripts/build-tweak.sh
```

Then locate the built dylib in the temporary build folder:

```text
/tmp/eevee-spotify-legacy-ios13-build/.theos/obj/debug/arm64/0Eevee.dylib
```

Assemble a local test IPA:

```sh
./scripts/assemble-ipa.sh \
  /path/to/Spotify-8.8.2.ipa \
  /tmp/eevee-spotify-legacy-ios13-build/.theos/obj/debug/arm64/0Eevee.dylib \
  /path/to/output.ipa
```

The assembly helper assumes the base IPA already has compatible injection pieces/slots. If your base IPA is different, you may need to adjust `LOAD_SLOT`.

Example:

```sh
LOAD_SLOT=Spotilife.dylib ./scripts/assemble-ipa.sh base.ipa 0Eevee.dylib output.ipa
```

Install the resulting IPA with your normal sideloading/TrollStore-style workflow.

## Notes

- This is not a polished release pipeline.
- The known target is iOS 13.x + Spotify 8.8.2.
- If something breaks on another setup, open an issue with device, iOS version, Spotify version, and install method.

