#!/bin/bash
set -euo pipefail

PROJECT_PATH="/Applications/GeoWCS/GeoWCS.xcodeproj"
SCHEME="GeoWCS"
SIMULATOR_NAME="iPhone 17 Pro Max"
DERIVED_DATA_PATH="/tmp/GeoWCSDerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/GeoWCS.app"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: Xcode project not found at $PROJECT_PATH" >&2
  exit 1
fi

# Boot simulator if needed (safe if already booted).
xcrun simctl boot "$SIMULATOR_NAME" >/dev/null 2>&1 || true

# Build app for simulator.
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

if [ ! -d "$APP_PATH" ]; then
  echo "Error: Built app not found at $APP_PATH" >&2
  exit 1
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")

# Install and launch app on booted simulator.
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"
open -a Simulator

echo "GeoWCS launched in Simulator ($SIMULATOR_NAME)."
