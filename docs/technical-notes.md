# Technical Notes

## Target

This tweak targets Spotify 8.8.2 on iOS 13.x. That app version was selected because it was the latest compatible Spotify release offered by the App Store on the test device.

The project has not been validated on other Spotify releases or other iOS versions. Compatibility with iOS 12, iOS 14+, or Spotify 8.6/8.7-era builds should be treated as unknown until tested.

## Key Implementation Points

1. Product-state handling

Spotify 8.8.2 no longer matched older Spotilife-era assumptions around `SPTProductState`. The tweak instead works through the classes available in this build, including `SPTCoreProductState`, `RCCFetchResponseHandler`, and auth session product-state update hooks.

2. Artist and album page behavior

The main playback/navigation breakthrough was targeting the free-tier artist and album hub resolvers:

- `SPTFreeTierArtistHubRemoteURLResolver`
- `SPTFreeTierAlbumHubRemoteURLResolver`

The important methods are `isOnDemandTrialEnabled` and `trackRowsEnabled`.

3. UI cleanup

The tweak removes the Premium tab from the adaptive tab bar and normalizes the visible account label in the UI. This is cosmetic and scoped to the client interface.

4. Lyrics replacement

Spotify's native lyrics path was not usable in this legacy setup, so the tweak injects a text view into the native lyrics controllers and fetches lyrics through LRCLIB.

Implementation details:

- `/api/get` first, `/api/search` as fallback
- Cache key: `artist|title`
- Single-flight request guard
- No caching of network errors
- Debounced refresh after track changes
- Proxy bypass in `NSURLSessionConfiguration`
- Custom fullscreen lyrics view wired to the native expand control

## Build Notes

The tweak is built with Theos for arm64 and an iOS 13.0 minimum deployment target.

The local helper builds from `/tmp` because Theos does not accept project paths containing spaces.

## Known Limitations

- Only iOS 13.x with Spotify 8.8.2 has been exercised.
- Compatibility with lower or higher Spotify versions is unknown.
- Compatibility with iOS 12 or iOS 14+ is unknown.
- Some behavior may still depend on server-side Spotify responses.
- Generated IPAs, app bundles, and compiled packages are intentionally not tracked.
