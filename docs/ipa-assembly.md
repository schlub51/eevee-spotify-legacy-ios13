# IPA Assembly Notes

These notes document the local packaging route used during the session. They are intentionally source-only notes; proprietary app bundles and generated IPAs are not tracked.

## Inputs

- Base IPA: `/Users/nono/Downloads/Spotify ++ 8.8.2 [starfiles.co].ipa`
- Built tweak dylib: `/tmp/eevee-ios13/.theos/obj/debug/arm64/0Eevee.dylib`
- Local assembly workspace: `/tmp/eevee-ipa`
- Final output: `/Users/nono/Downloads/Spotify-EeveeLegacy-8.8.2.ipa`

## Packaging Shape

The IPA already contained tweak loading slots:

- `Spotilife.dylib`
- `Sposify.dylib`
- `SposifyFix.dylib`
- `CydiaSubstrate.framework`

The working assembly path replaced the active tweak dylib with the newly built Eevee legacy tweak and replaced unused companion tweak slots with no-op stubs.

The later final package normalized the naming to `EeveeLegacy.dylib` to remove confusion between the load slot and the actual tweak identity.

## Verification Used

Checks performed during packaging:

```sh
otool -L Frameworks/Spotilife.dylib
nm -u Frameworks/Spotilife.dylib | grep MSHook
ldid -e Payload/Spotify.app/Spotify
ldid -h Frameworks/Spotilife.dylib
unzip -l Spotify-EeveeLegacy-8.8.2.ipa
```

Expected signs:

- The tweak links against the embedded CydiaSubstrate framework.
- `_MSHookMessageEx` is present.
- Spotify entitlements are preserved before fakesigning.
- The output IPA contains the main app binary, the tweak dylib, no-op stubs, and CydiaSubstrate.

