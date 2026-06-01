#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

export CURRENT_PROJECT_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
xcodegen generate

if [ -n "${VERSION:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" AinoteHaiteku/Info.plist
fi

xcodebuild build \
  -project ainote-haiteku.xcodeproj \
  -scheme ainote-haiteku \
  -configuration Release \
  -derivedDataPath build/

if [ -n "${VERSION:-}" ]; then
  APP_PATH="build/Build/Products/Release/ainote-haiteku.app"
  DMG_NAME="ainote-haiteku-${VERSION}-macos.dmg"
  create-dmg \
    --volname "ainote-haiteku" \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "ainote-haiteku.app" 150 200 \
    --app-drop-link 450 200 \
    --no-internet-enable \
    "$DMG_NAME" "$APP_PATH"
  echo "Created $DMG_NAME"
fi
