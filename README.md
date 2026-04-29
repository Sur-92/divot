# Divot

A native macOS golf tracker, built in Swift / SwiftUI / SwiftData.

Divot keeps your rounds, shots, courses, clubs, practice notes, video
bookmarks, and a USGA-style handicap index — all local, no cloud sync,
no analytics, no telemetry. The data store lives in the app's sandbox
container and never leaves your machine.

## Features

- **Rounds** — full 18, front 9, or back 9. Per-hole scorecard with par,
  score, putts, fairway / GIR flags, yardage, handicap index, notes.
  Color-coded score marks (eagle / birdie / par / bogey / double / triple).
- **Shot log** — every shot recorded with club, distance, lie, result, notes.
  Drives the longest-drive and trimmed-average-drive stats.
- **Courses** — eight pre-seeded courses from south-central Pennsylvania
  (Royal Oaks, Iron Valley, Fairview, Pine Meadows, Dauphin Highlands,
  Blue Mountain, Foxchase, Deer Valley) plus an indoor sim venue
  (Woods & Irons). Per-tee yardages, ratings, slopes; per-hole pars and
  handicap indices.
- **Clubs** — color-coded by category (driver / fairway / hybrid / iron
  set / wedge / putter). Soft-retire keeps history without clutter.
- **Videos** — quick bookmarks for YouTube coaching clips. Tap-to-open
  in your default browser.
- **Map** — MapKit satellite view with two-point geodesic distance
  measurement (CLLocation, USGA-friendly meters → yards). Address-based
  fly-to for any saved course.
- **PGA** — current tournament leaderboard and news (ESPN + PGA Tour
  feeds, on-demand only). Includes Open-Meteo weather for the host
  course. Handles team events (e.g. Zurich Classic).
- **Stats** — averaged per-9-hole scoring (so 9- and 18-hole rounds are
  comparable), fairways / GIR / putts trends, longest drive, trimmed
  average drive, eagles / birdies / pars, best par-or-better streak.
- **Handicap** — USGA World Handicap System: net-double-bogey-capped
  adjusted gross, score differentials, last-20 pool, paired 9-hole
  rounds combined into 18-hole-equivalent entries, best-N average,
  small-pool adjustments (-2.0 / -1.0).
- **Audit log** — every meaningful write (insert, update, retire,
  archive, delete) is captured for traceability.

## Architecture

- **SwiftUI** for all views (no AppKit-bridged UI except where macOS
  needs it — `NSWorkspace.open` for browser hand-off, `NSImage` for
  asset loading).
- **SwiftData** (`@Model`) for persistence. One on-disk store, in the
  app's sandbox `Library/Application Support/`.
- **MapKit** + **CoreLocation** for the Map screen — no JS bridges,
  no WebView.
- **CLGeocoder** for address-to-coordinate refinement on course
  selection.
- A small **TempCleaner** wipes `tmp/`, `Caches/`, and `HTTPStorages/`
  on launch and termination so transient URL caches don't accumulate.

## Building

```bash
brew install xcodegen          # if you don't have it
git clone https://github.com/Sur-92/divot.git
cd divot
xcodegen generate              # writes Divot.xcodeproj from project.yml
open Divot.xcodeproj
```

Then build/run the `Divot` scheme in Xcode. Targets **macOS 14+**.

The first run will:
- Seed the eight bundled courses + sim venue
- Seed an initial set of bag clubs (you can edit/delete freely)
- Prompt for Location permission (only used for the Map screen — declining
  doesn't break anything else)

## Sandbox & entitlements

Minimal by design:

| Entitlement | Why |
|---|---|
| `app-sandbox` | Standard app sandbox |
| `network.client` | PGA / ESPN / Open-Meteo fetches; MapKit tiles |
| `personal-information.location` | Map screen "Mark Here" GPS |
| `files.user-selected.read-only` | Future import of scorecards |

No iCloud entitlement, no contacts, no calendar, no microphone, no
camera, no shared containers, no XPC services, no helper tool.

## License

[MIT](LICENSE) — except for the bundled golf-course logo image assets,
which are trademarks of their respective clubs. See LICENSE for details.
