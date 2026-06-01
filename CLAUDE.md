# ainote-haiteku

A menu-bar resident macOS app. It plays a random ainote sound every time you press Enter (or Ctrl+M),
but stays quiet while a Google Meet tab is open in Google Chrome. Built with Swift (AppKit).

## Build & Test

```bash
xcodegen generate
xcodebuild -project ainote-haiteku.xcodeproj -scheme ainote-haiteku -configuration Release build
xcodebuild -project ainote-haiteku.xcodeproj -scheme ainote-haitekuTests -configuration Debug test
swiftlint
```

`scripts/build.sh` runs `xcodegen generate` plus the Release build together.

## State model

Sound plays only when `manually enabled AND no Meet open` — an orthogonal AND gate.

- Manual toggle (`AppState.manualEnabled`): master switch, persisted in UserDefaults.
- Auto gate (`AppState.chromeStatus`): result of scanning Chrome tabs; suppresses only when Meet is
  detected.
- Chrome not running or detection unavailable (missing permission) does NOT suppress (sound plays) —
  fail-safe.

## Permissions

- Accessibility: required for the global key monitor (`NSEvent.addGlobalMonitorForEvents`).
- Automation (Google Chrome): required to read tab URLs via Apple Events.
- Login item: `SMAppService`; registered automatically on first launch.

Assumes a non-sandboxed build (`app-sandbox = false`).

## Development Rules

- All user-facing UI text (menu items, labels, etc.) must be in English.
- After adding files to Resources, run `xcodegen generate` before building.
- When changing features, update the relevant sections of README.md.

## Manual UI Verification

When verifying UI changes, quit the running app, rebuild, and relaunch. Launch from the absolute path
inside DerivedData rather than `/Applications` or a previously installed version.

```bash
pkill -x ainote-haiteku 2>/dev/null
bash scripts/build.sh
open build/Build/Products/Release/ainote-haiteku.app
```
