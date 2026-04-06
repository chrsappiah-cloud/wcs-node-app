#!/bin/bash
set -euo pipefail

PROJECT_PATH="/Applications/GeoWCS/GeoWCS.xcodeproj"
SCHEME="GeoWCS"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro Max"
RESULT_BUNDLE="/Users/christopherappiah-thompson/Development/GeoWCS/build/test-results/PostAuthSmoke.xcresult"
SCREENSHOT_DIR="/Users/christopherappiah-thompson/Development/GeoWCS/build/appstore-screenshots/post-auth-smoke"

mkdir -p "$(dirname "$RESULT_BUNDLE")"
mkdir -p "$SCREENSHOT_DIR"
rm -rf "$RESULT_BUNDLE"
rm -f "$SCREENSHOT_DIR"/*.png

echo "Running post-auth smoke test with stub auth..."
SCREENSHOT_DIR="$SCREENSHOT_DIR" xcodebuild test \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:GeoWCSUITests/GeoWCSCriticalFlowsUITests/testPostAuthSmokeAndCaptureScreens \
  -resultBundlePath "$RESULT_BUNDLE"

echo "Screenshots captured to: $SCREENSHOT_DIR"
ls -lh "$SCREENSHOT_DIR"

echo "Per-test summary:"
xcrun xcresulttool get --legacy --format json --path "$RESULT_BUNDLE" \
  | /usr/bin/python3 - <<'PY'
import json, sys

data = json.load(sys.stdin)
actions = data.get("actions", {}).get("_values", [])
for action in actions:
    test_ref = action.get("actionResult", {}).get("testsRef")
    if not test_ref:
        continue
    break
else:
    print("No test results found")
    raise SystemExit(0)

print("Use xcode result bundle for detailed inspection:")
print("- /Users/christopherappiah-thompson/Development/GeoWCS/build/test-results/PostAuthSmoke.xcresult")
PY
