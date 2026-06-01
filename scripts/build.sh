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
