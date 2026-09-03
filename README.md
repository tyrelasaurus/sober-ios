# Sober for iOS

A private sobriety tracker for iPhone: streak, money saved, sleep, mood,
weight, journaling, and a recovery-milestone timeline. All data is stored
locally on your phone — nothing is uploaded anywhere.

This is a native SwiftUI companion to [Sober for macOS](https://github.com/tyrelasaurus/sober-app),
built independently (no shared code — Electron/Node.js doesn't run on iOS)
but matching its data model, business logic, and feature set exactly.

## Status

Local-only, full feature parity with the Mac app's 8 screens. There is
**no sync between this app and the Mac app yet** — each keeps its own
separate data. Real device use and iCloud sync between the two require a
paid Apple Developer Program account and are a planned follow-up; for now
this runs in the iOS Simulator.

## Features

- Streak tracking with money saved and drinks avoided, which keep
  accumulating even across a relapse.
- Daily check-ins for mood, sleep, cravings, exercise (with duration and
  intensity), and journal notes, with optional trigger tags.
- Calendar view of every check-in, color-coded by mood.
- Insights that compare check-ins against each other (e.g. average
  craving on short-sleep nights vs. not, or by exercise duration/
  intensity) once there's enough data to be meaningful.
- Milestones with a permanent "farthest ever reached" record, separate
  from the current streak.
- Optional weight tracking with a trend chart.

## Setup

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The `.xcodeproj` is generated from
`project.yml`, not committed as the source of truth — regenerate it
after pulling changes or editing `project.yml`:

```bash
xcodegen generate
```

Then open `Sober.xcodeproj` in Xcode, or build from the command line:

```bash
xcodebuild -project Sober.xcodeproj -scheme Sober \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Run tests

```bash
xcodebuild -project Sober.xcodeproj -scheme Sober \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Architecture

- `Sober/Models/` — data types (`AppData`, `CheckIn`, `Period`, etc.),
  matching the Mac app's `sober-data.json` shape field-for-field.
- `Sober/Logic/` — pure business logic ported from the Mac app's
  `calc.js`: streak math, money/savings, milestones, insights
  correlations, weight stats. No UIKit/SwiftUI dependencies, fully
  unit-tested.
- `Sober/Storage/Store.swift` — local JSON persistence (`ObservableObject`,
  published to SwiftUI views), with the same field-level partial-update
  merge semantics as the Mac app's `store.js` — a quick mood-only update
  must never wipe fields it doesn't mention.
- `Sober/Views/` — one folder per screen, mirroring the Mac app's sidebar
  sections, presented here as an iOS tab bar.

## Notes

- Requires iOS 17 or later.
- This is a personal tracking tool, not a medical device — it doesn't
  replace professional treatment or support.
