# ainote-haiteku

A menu-bar resident version of [ainote](https://github.com/negipo/ainote). It plays a random sound
every time you press Enter (or Ctrl+M), but stays quiet while a Google Meet tab is open in Google
Chrome — the "high-tech" (haiteku) edition.

## Features

- Lives in the menu bar (no Dock icon). An x badge on the bottom-right of the icon indicates the
  inactive state.
- Plays a random ainote sound on Enter / keypad Enter / Ctrl+M.
- Automatically stays quiet while any Chrome tab has `meet.google.com` open.
- The menu shows the current status (including Chrome and key-monitor state), a volume slider, a
  manual enable/disable toggle, and a Settings submenu (Launch at Login, Acquire Accessibility
  Permission).
- Launches automatically at login (registered as a login item on first launch).

## Installation

```bash
brew install --cask negipo/tap/ainote-haiteku
```

The app is ad-hoc signed (no Apple Developer ID); the cask clears the quarantine attribute
automatically. On first launch, grant Accessibility and Automation (Google Chrome) permissions under
System Settings > Privacy & Security.

## State model

Sound plays only when `manually enabled AND no Meet open`. The two are orthogonal gates: turning it
off manually keeps it silent regardless of Meet, and when a Meet ends it resumes as long as it is
still manually enabled. When Chrome is not running or the required permission is missing, it does not
suppress (it plays) — a fail-safe default.

## Permissions

The following are required on first launch:

- Accessibility: used to observe key presses.
- Automation (Google Chrome): used to read open tab URLs (Meet detection).

Grant both under System Settings > Privacy & Security.

## Development

Requires Xcode (including Command Line Tools),
[XcodeGen](https://github.com/yonaskolb/XcodeGen), and
[SwiftLint](https://github.com/realm/SwiftLint).

```bash
git clone https://github.com/negipo/ainote-haiteku.git
cd ainote-haiteku
bash scripts/build.sh   # xcodegen generate + Release build
open build/Build/Products/Release/ainote-haiteku.app
```

Test and lint:

```bash
xcodegen generate
xcodebuild -project ainote-haiteku.xcodeproj -scheme ainote-haitekuTests -configuration Debug test
swiftlint
```

## License

- The code is MIT licensed.
- The sound files (`AinoteHaiteku/Resources/*.m4a`) come from
  [ainote](https://github.com/negipo/ainote) and are published under
  [CC BY](http://creativecommons.org/licenses/by/4.0/).
