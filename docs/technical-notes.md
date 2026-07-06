# Technical Notes

## Target

Known target: Spotify 8.8.2 on iOS 13.x.

Spotify 8.8.2 was chosen because it was the newest compatible version offered by the App Store on the test device.

Other Spotify versions and iOS releases are untested.

The committed source is the latest local snapshot. It includes the v58 product-state work plus later UI and lyrics fixes.

## Key Implementation Points

1. Product-state handling

Spotify 8.8.2 did not match older Spotilife-era `SPTProductState` assumptions. This version uses `SPTCoreProductState`, `RCCFetchResponseHandler`, and auth session product-state hooks instead.

2. Artist and album page behavior

The key playback/navigation hooks are:

- `SPTFreeTierArtistHubRemoteURLResolver`
- `SPTFreeTierAlbumHubRemoteURLResolver`

Main methods: `isOnDemandTrialEnabled` and `trackRowsEnabled`.

3. UI cleanup

Removes the Premium tab and normalizes the visible account label.

4. Lyrics replacement

Injects a text view into Spotify's lyrics controllers and fetches lyrics through LRCLIB.

Implementation details:

- `/api/get` first, `/api/search` as fallback
- Cache key: `artist|title`
- Single-flight request guard
- No caching of network errors
- Debounced refresh after track changes
- Proxy bypass in `NSURLSessionConfiguration`
- Custom fullscreen lyrics view wired to the native expand control

## Build Notes

The tweak is built with Theos for arm64 and iOS 13.0+.

The local helper builds from `/tmp` because Theos does not accept project paths containing spaces.

## Known Limitations

- Only iOS 13.x with Spotify 8.8.2 has been exercised.
- Compatibility with lower or higher Spotify versions is unknown.
- Compatibility with iOS 12 or iOS 14+ is unknown.
- Some behavior may still depend on server-side Spotify responses.
- Generated IPAs and app bundles are not tracked or published.
- GitHub releases may include a compiled `.deb` containing only the tweak files.
