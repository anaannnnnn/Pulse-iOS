# Pulse for iOS: design notes

**Concept.** Pulse is a private screening room. The app is the house lights going down: pure black, one warm tungsten light, serif titles like a title card, monospaced timecodes like a slate.

**Subject vocabulary.** projector beam, film leader, frame counter, slate, timecode, reel, sprocket, marquee, ticket stub, aperture, house lights.

**Pillars.** quiet black stage · content is the light source · numbers read like timecodes · glass only where something floats.
**Anti-pillars.** a streaming-service clone (no crimson wordmark, no red haze) · decoration over content.

**Axis picks.** layout: full-bleed hero + rails · type: New York serif for titles, SF for UI, SF Mono for timecodes (all system fonts, all Dynamic Type) · colour: monochrome black + one spot light (Tungsten `#F2B24A`, user-selectable) · material: pure black, hairline slates, Liquid Glass on the functional layer only · motion: physical springs, one orchestrated hero entrance, film-strip pager.

**Spent boldness.** The Home hero: left-aligned serif title, timecode line, film-strip frame counter that fills while a feature is on screen.

## Rules
- Glass (`pulseGlass`, `pulseCapsuleGlass`, glass buttons) only on floating controls and system chrome. Grouped content uses `pulsePanel()` or `pulsePill()`.
- Radius by role (`Theme.Radius`): card 10 (posters), control 14, panel 20, sheet 28; primary actions are capsules.
- Text sizes are text styles (`.title3`, `.footnote`, …) so Dynamic Type works; fixed sizes only for brand marks and icons.
- Edge-to-edge screens read the real safe area (`DeviceInsets.top`), never a hard-coded offset. Hero height derives from width and screen height.
- Motion respects Reduce Motion; ambient background is static.
