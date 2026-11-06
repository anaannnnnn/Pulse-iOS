# Pulse for iOS

Native SwiftUI client for the Pulse personal streaming server (pCloud + TorBox library, ThePornDB / StashDB metadata).
It speaks the server's `/api` contract (`docs/API.md` in the Pulse repo) and mirrors the web app's Violet Glass design.

* iOS 18+ (Liquid Glass automatically on iOS 26+ when built with Xcode 26)
* Swift 6 package, no third-party dependencies
* Everything works offline of any server through the built-in **Demo library** (passcode `6442`)

## Features

| Area | What you get |
|---|---|
| Lock | Server-enforced passcode keypad, Face ID / Touch ID via Keychain, auto-lock, privacy cover in the app switcher, blur-thumbnails option |
| Home | Greeting, swipeable hero banner, library stats, rails: continue watching, recent, favourites, top performers, unwatched |
| Library | Adaptive grid or list, debounced search, sort (7 orders), filter sheet (tags, performers, studios, year, length, progress, source, match state), infinite scroll |
| Search | Global search across videos, performers, studios with recent searches |
| Detail | Stretchy parallax header, zoom transition from cards, play / resume, favourite, watchlist, cast, tags, "at a glance", metadata edit, find / apply / unmatch match |
| People | Performer grid with profile (bio, facts, aliases, gallery, links, refresh from ThePornDB or StashDB), studios list and pages |
| Saved | Favourite videos, watchlist, followed people |
| Tonight | Pick your time budget and get three unwatched suggestions |
| Player | AVPlayer with direct → HLS → server-proxy fallback, resume, progress sync, scrubber with time bubble, double-tap skip, brightness and volume edge gestures, swipe-down minimise, pinch to fill, speed, quality, WebVTT subtitles, Picture in Picture, AirPlay, background audio, up-next countdown |
| Settings | Playback, privacy and passcode change, pCloud (connect, folder picker, scan progress), TorBox (link, downloads, add magnet, import), matching dashboard and review queue, metadata sources with connection tests, data clearing, about |

## Layout

```
Package.swift
Sources/
  PulseCore/      Models, PulseAPI protocol, HTTP client, demo client, @Observable stores (builds and tests on Linux)
  PulseDesign/    Violet Glass tokens, glass modifiers, aurora, buttons, art, shared components
  PulseFeatures/  Screens: Home, Library, Search, Detail, People, Saved, Tonight, Player, Settings, Auth
  PulseApp/       PulseRootView (phase routing, tabs, privacy shield). The only thing the app target imports
App/              @main, Info.plist, asset catalog, privacy manifest
project.yml       XcodeGen spec for the app target
azure-pipelines.yml
scripts/          CI helpers
Tests/PulseCoreTests
```

## Run it

```bash
brew install xcodegen
scripts/generate-project.sh     # creates Pulse.xcodeproj
open Pulse.xcodeproj            # choose your team under Signing & Capabilities, run on a device or simulator
```

Or open `Package.swift` in Xcode to work on the modules directly.

On first launch enter the address of your server (`192.168.1.20:8787`, a Tailscale name, or your tunnel URL) or tap **Explore the demo library**.

## Tests

```bash
swift test --filter PulseCoreTests          # 19 tests: decoding, stream fallback, WebVTT, URLs, stores
```

`PulseCore` has no UIKit/SwiftUI imports and is the same code path the app uses, so the logic is verified off-device.

## Azure DevOps

`azure-pipelines.yml` runs on a Microsoft-hosted `macos-15` agent:

1. **Validate** – unit tests and a full iOS compile of every package target (on every PR)
2. **Archive** – XcodeGen, installs your distribution certificate and profile, archives, exports `Pulse.ipa`, publishes it as the `Pulse-ios` artifact
3. **Optional** – run with `uploadToTestFlight: true` to push the IPA to TestFlight with an App Store Connect API key

Setup (once):

| Kind | Name | Notes |
|---|---|---|
| Variable group | `pulse-ios-signing` | `P12_PASSWORD` (secret), `APPLE_TEAM_ID`, `PROVISIONING_PROFILE_NAME`, `ASC_KEY_ID`, `ASC_ISSUER_ID` |
| Secure file | `distribution.p12` | Apple Distribution certificate and private key |
| Secure file | `Pulse_AppStore.mobileprovision` | App Store profile for `app.pulse.ios` |
| Secure file | `AuthKey_<ASC_KEY_ID>.p8` | only for TestFlight upload |

Change the bundle id in `project.yml` (`PRODUCT_BUNDLE_IDENTIFIER`) and the `bundleId` variable in the pipeline together. Tag `v1.2.0` to stamp that marketing version.

## Server notes

* The session is the server's `pulse_auth` cookie. The app keeps it in the shared cookie store and hands it to AVPlayer for same-host URLs, so the proxy fallback works behind the passcode.
* `Info.plist` allows cleartext HTTP so a LAN address such as `http://192.168.1.20:8787` works. For an App Store release behind HTTPS only, remove `NSAllowsArbitraryLoads` and keep `NSAllowsLocalNetworking`.
* Fonts: the display face is "Unbounded" and falls back to SF Rounded. To use it, add the font files to the app target and list them under `UIAppFonts`.

## Not included

Pairing/multi-user (the server has none yet), the web app's archive browser, and push notifications.
