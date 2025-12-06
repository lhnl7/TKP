# tkp — TikTok-style local player (complete project)

This repo contains a minimal iOS project that:
- Lets user pick videos from Photos (PHPicker) and plays them in a vertical, TikTok-like feed.
- Includes a GitHub Actions workflow that builds an unsigned IPA (no Apple Developer account required).

## How to use
1. Upload this repo to GitHub (upload all files, **do not** upload the zip itself).
2. Go to Actions → "Build Unsigned IPA" → Run workflow.
3. Download artifact `tkp-unsigned-ipa` when the workflow finishes. Inside you'll find `tkp_unsigned.ipa`.

## Notes
- The IPA is unsigned. Install with Sideloadly / AltStore.
- The app requests photo library permission to pick videos.
- Picked videos are copied into the app's Documents/videos folder.
