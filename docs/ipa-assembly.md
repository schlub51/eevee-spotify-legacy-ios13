# IPA Assembly Notes

These notes document the packaging shape used for local testing. They are intentionally source-only notes; proprietary app bundles and generated IPAs are not tracked.

## Inputs

- A locally available, decrypted Spotify 8.8.2 IPA
- A built `0Eevee.dylib` from this Theos project
- A temporary local assembly workspace
- A locally generated output IPA

## Packaging Shape

The IPA already contained tweak loading slots:

- `Spotilife.dylib`
- `Sposify.dylib`
- `SposifyFix.dylib`
- `CydiaSubstrate.framework`

The working assembly path replaced the active tweak dylib with the newly built Eevee legacy tweak and replaced unused companion tweak slots with no-op stubs.

The load slot name may differ from the tweak identity depending on the base IPA. The helper script defaults to the existing `Spotilife.dylib` slot because it is commonly present in the tested base.

## Verification Used

Checks performed during packaging:

```sh
otool -L Frameworks/Spotilife.dylib
nm -u Frameworks/Spotilife.dylib | grep MSHook
ldid -e Payload/Spotify.app/Spotify
ldid -h Frameworks/Spotilife.dylib
unzip -l output.ipa
```

Expected signs:

- The tweak links against the embedded CydiaSubstrate framework.
- `_MSHookMessageEx` is present.
- Spotify entitlements are preserved before fakesigning.
- The output IPA contains the main app binary, the tweak dylib, no-op stubs, and CydiaSubstrate.
