# Reddit Post Draft

Title idea:

`I vibe-coded a small Spotify 8.8.2 compatibility tweak for iOS 13`

Post:

Hey, just sharing this in case there are still a few people around using old checkra1n-era devices on iOS 13.

I had an older iPhone that was basically still useful to me as a music device, but Spotify had become the annoying part. The App Store only offered me Spotify 8.8.2 as the latest compatible version for that iOS version, and I kept running into the usual legacy-app mess: broken/limited behavior, old tweak assumptions not quite matching anymore, lyrics not loading properly, etc.

So I spent an afternoon doing pure vibe coding with AI assistants and a real device plugged in, going back and forth: inspect symbols, build the tweak, install, test, fail, adjust hooks, repeat.

The result is a small Theos tweak targeting Spotify 8.8.2 on iOS 13.x. The main useful bits are:

- hooks adapted for Spotify 8.8.2 internals
- artist/album pages made usable again through the free-tier hub resolver path
- Premium tab cleanup
- visible account label cleanup
- replacement lyrics view using LRCLIB
- build notes and IPA assembly notes

Repo:

https://github.com/schlub51/eevee-spotify-legacy-ios13

Important notes:

- This is source-only. I am not uploading IPAs, app bundles, or compiled Spotify builds.
- Tested target is iOS 13.x + Spotify 8.8.2.
- I have not tested iOS 12, iOS 14+, or other Spotify versions yet.
- This was mostly made because I wanted my old phone to feel useful again, so treat it as an experiment rather than a polished release.

Would be curious if anyone else is still on iOS 13/checkra1n-era devices and wants to test or compare notes.

