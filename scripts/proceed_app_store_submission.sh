#!/bin/bash
#
# proceed_app_store_submission.sh
# Runs release preflight checks, exports an IPA with a PATH-safe command,
# and optionally validates/uploads via altool.
#
# Usage:
#   ./scripts/proceed_app_store_submission.sh
#
# Optional environment variables:
#   APP_STORE_CONNECT_KEY=<key-id>
#   APP_STORE_CONNECT_ISSUER=<issuer-id>
#   APP_STORE_SUBMIT=1                # upload after validation
#   PROJECT_PATH=<xcodeproj path>     # default /Applications/GeoWCS/GeoWCS.xcodeproj
#   SCHEME=<scheme>                   # default GeoWCS
#   ARCHIVE_PATH=<archive path>       # default build/GeoWCS-prod.xcarchive
#   EXPORT_PLIST=<plist path>         # default build/export-appstore.plist
#   EXPORT_PATH=<export dir>          # default build

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PACKET="APP_STORE_SUBMISSION_PACKET.md"
IPA="build/GeoWCS.ipa"
PROJECT_PATH="${PROJECT_PATH:-/Applications/GeoWCS/GeoWCS.xcodeproj}"
SCHEME="${SCHEME:-GeoWCS}"
ARCHIVE_PATH="${ARCHIVE_PATH:-build/GeoWCS-prod.xcarchive}"
EXPORT_PLIST="${EXPORT_PLIST:-build/export-appstore.plist}"
EXPORT_PATH="${EXPORT_PATH:-build}"

APP_STORE_CONNECT_KEY="${APP_STORE_CONNECT_KEY:-}"
APP_STORE_CONNECT_ISSUER="${APP_STORE_CONNECT_ISSUER:-}"
APP_STORE_SUBMIT="${APP_STORE_SUBMIT:-0}"

RSYNC_SAFE_PATH="/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin"

is_placeholder_value() {
  local value="$1"
  [[ -z "$value" || "$value" == *"<"* || "$value" == *"YOUR_"* || "$value" == *"ISSUER_ID"* || "$value" == *"KEY_ID"* ]]
}

if [[ ! -x scripts/app_store_preflight.sh ]]; then
  chmod +x scripts/app_store_preflight.sh
fi

scripts/app_store_preflight.sh "$PACKET" "$IPA"

echo
echo "Exporting IPA with rsync-safe PATH (fixes xcodebuild export Copy failed issues)..."
if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "Archive not found at $ARCHIVE_PATH, creating archive first..."
  xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH"
fi

env PATH="$RSYNC_SAFE_PATH" xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates

if [[ ! -f "$IPA" ]]; then
  echo "ERROR: Export completed but IPA was not found at $IPA"
  exit 1
fi

echo "IPA export complete: $IPA"

if [[ -n "$APP_STORE_CONNECT_KEY" || -n "$APP_STORE_CONNECT_ISSUER" ]]; then
  if is_placeholder_value "$APP_STORE_CONNECT_KEY" || is_placeholder_value "$APP_STORE_CONNECT_ISSUER"; then
    echo
    echo "ERROR: Placeholder App Store Connect values detected."
    echo "Set real values for APP_STORE_CONNECT_KEY and APP_STORE_CONNECT_ISSUER before validate/upload."
    exit 1
  fi

  if [[ -z "$APP_STORE_CONNECT_KEY" || -z "$APP_STORE_CONNECT_ISSUER" ]]; then
    echo
    echo "ERROR: Command-line validation/upload requires both APP_STORE_CONNECT_KEY and APP_STORE_CONNECT_ISSUER"
    exit 1
  fi

  echo
  echo "Validating IPA with App Store Connect..."
  xcrun altool --validate-app \
    -f "$IPA" \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_KEY" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER"

  if [[ "$APP_STORE_SUBMIT" == "1" ]]; then
    echo
    echo "Uploading IPA to App Store Connect..."
    xcrun altool --upload-app \
      -f "$IPA" \
      -t ios \
      --apiKey "$APP_STORE_CONNECT_KEY" \
      --apiIssuer "$APP_STORE_CONNECT_ISSUER"
  else
    echo
    echo "Validation complete. Set APP_STORE_SUBMIT=1 to perform upload in this script."
  fi
fi

echo
echo "Preflight passed."
echo "Next: complete App Store Connect UI submission at:"
echo "https://appstoreconnect.apple.com/apps"
echo

echo "Checklist source: APP_STORE_SUBMISSION_PACKET.md"
echo "Runbook source: DEPLOYMENT.md"

open "https://appstoreconnect.apple.com/apps"
