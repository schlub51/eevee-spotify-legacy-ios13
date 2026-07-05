# Project Progress Review

## Context

This project came from a very concrete problem: an older iPhone on iOS 13 had become much less useful because modern Spotify no longer worked on it. The work focused on Spotify 8.8.2, a legacy version that could still run on the device, then adapting an Eevee/Spotilife-style tweak so the app felt usable again.

## Final Snapshot

- Tweak source: `/tmp/eevee-ios13/Tweak.x`
- Final source version: v83
- Final IPA produced: `/Users/nono/Downloads/Spotify-EeveeLegacy-8.8.2.ipa`
- Base app used during assembly: `Spotify ++ 8.8.2 [starfiles.co].ipa`
- Minimum runtime target: iOS 13.0
- Device test target during the session: iOS 13.5 era device
- Build system: Theos

## Key Modifications

1. Migrated the tweak to Spotify 8.8.2 internals.

Older Spotilife-style hooks no longer mapped cleanly because `SPTProductState` had changed. The working path moved to `SPTCoreProductState`, `RCCFetchResponseHandler`, auth session product-state updates, and free-tier resolver classes.

2. Recovered artist and album page selection.

The main breakthrough was reproducing the EeveeSpotify approach on:

- `SPTFreeTierArtistHubRemoteURLResolver`
- `SPTFreeTierAlbumHubRemoteURLResolver`

The important methods were `isOnDemandTrialEnabled` and `trackRowsEnabled`.

3. Cleaned up the app UI.

The tweak removes the Premium tab from the adaptive tab bar and cosmetically rewrites the visible `Spotify Free` account label to `Spotify Premium`, so the app no longer constantly exposes the broken legacy/free-tier surfaces.

4. Added a native-looking lyrics replacement.

The native lyrics endpoint was not usable in this legacy build, so the tweak injects a `UITextView` into Spotify's lyrics view controllers and fetches lyrics from LRCLIB.

Important implementation details:

- `/api/get` first, `/api/search` as fallback
- Cache key: `artist|title`
- Single-flight request guard
- No caching of network errors, so transient failures can retry
- 0.5s debounce before refreshing after track changes
- Proxy bypass in `NSURLSessionConfiguration` to avoid CFNetwork 310 failures
- Custom full-screen lyrics view with the native expand button wired to it

5. Built a standalone IPA.

The final packaging route avoided Mach-O load-command surgery where possible by reusing existing injection slots, then later renamed the payload cleanly to `EeveeLegacy.dylib`. The final IPA preserved original entitlements and was fakesigned with `ldid`.

## Important Fixes Along The Way

- SDK 26.x output was risky on iOS 13, so the project settled on the Theos iPhoneOS 16.5 SDK.
- Missing Substrate linkage meant the tweak did not inject until `0Eevee_LIBRARIES = substrate` was added.
- `scp` over `iproxy` produced zero-byte transfers, so the session used base64 transfer over SSH.
- `keyWindow` issues were fixed by iterating application windows.
- Swift lyrics controllers required hooking actual runtime class names under `Lyrics_CoreImpl`.
- The expand button was an `EncoreButton`, a `UIControl` subclass, not a `UIButton`.
- Lyrics could race after skipping tracks; stale results are avoided by keying refreshes to the current stable title/artist pair.
- Network timeouts previously poisoned the cache with "No lyrics found"; network errors now abort without caching.

## Known Limitations

- Very High / HiFi audio remained a server-side limitation.
- One audio ad was observed during testing; automatic ad skipping was identified but not implemented.
- The final `Spotify-EeveeLegacy-8.8.2.ipa` still needed a separate full install validation after the last direct dylib push.
- There was an intermittent launch timing issue where the app could briefly show old free-tier behavior.

## Session Result

The user confirmed the end-to-end result felt clean and functional, including the repaired lyrics expansion behavior:

> "Là ça y est, j'ai l'impression qu'on a quelque chose de propre, fonctionnel, de bout en bout."

