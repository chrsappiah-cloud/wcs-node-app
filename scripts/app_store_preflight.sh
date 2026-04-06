#!/bin/bash
#
# app_store_preflight.sh
# Runs preflight checks before App Store Connect submission.
#
# Usage:
#   ./scripts/app_store_preflight.sh [packet-path] [ipa-path]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PACKET_PATH="${1:-APP_STORE_SUBMISSION_PACKET.md}"
IPA_PATH="${2:-build/GeoWCS.ipa}"
VALIDATOR="scripts/validate_app_store_packet.sh"
INFO_PLIST="/Applications/GeoWCS/GeoWCS/Info.plist"
KEY_FILE_DIR="$HOME/.appstoreconnect/private_keys"

APP_STORE_CONNECT_KEY="${APP_STORE_CONNECT_KEY:-}"
APP_STORE_CONNECT_ISSUER="${APP_STORE_CONNECT_ISSUER:-}"

is_placeholder_value() {
  local value="$1"
  [[ -z "$value" || "$value" == *"<"* || "$value" == *"YOUR_"* || "$value" == *"ISSUER_ID"* || "$value" == *"KEY_ID"* ]]
}

errors=0
warnings=0

print_header() {
  echo -e "${BLUE}===================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}===================================================${NC}"
}

ok() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  warnings=$((warnings + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  errors=$((errors + 1))
}

print_header "App Store Preflight"

echo "Packet: $PACKET_PATH"
echo "IPA:    $IPA_PATH"

print_header "Packet Validation"
if [[ ! -x "$VALIDATOR" ]]; then
  fail "Validator missing or not executable: $VALIDATOR"
else
  if "$VALIDATOR" "$PACKET_PATH"; then
    ok "Packet validation passed"
  else
    fail "Packet validation failed"
  fi
fi

print_header "Artifact Checks"
if [[ -f "$IPA_PATH" ]]; then
  ok "IPA exists"
else
  fail "IPA not found: $IPA_PATH"
fi

if [[ -f "$IPA_PATH" ]]; then
  size_bytes=$(wc -c < "$IPA_PATH" | tr -d ' ')
  if [[ "$size_bytes" -gt 0 ]]; then
    ok "IPA size is $size_bytes bytes"
  else
    fail "IPA size is zero"
  fi
fi

print_header "Upload Metadata Checks"
if grep -Fq "Upload: SUCCEEDED" "$PACKET_PATH"; then
  ok "Packet records successful upload"
else
  warn "Packet does not explicitly include 'Upload: SUCCEEDED'"
fi

if grep -Fq "Delivery UUID:" "$PACKET_PATH"; then
  ok "Packet includes Delivery UUID"
else
  warn "Packet missing Delivery UUID"
fi

print_header "App Store Connect Auth Checks"
if [[ -z "$APP_STORE_CONNECT_KEY" || -z "$APP_STORE_CONNECT_ISSUER" ]]; then
  warn "APP_STORE_CONNECT_KEY and APP_STORE_CONNECT_ISSUER are not both set"
  warn "Command-line validate/upload requires both values"
else
  if is_placeholder_value "$APP_STORE_CONNECT_KEY" || is_placeholder_value "$APP_STORE_CONNECT_ISSUER"; then
    warn "APP_STORE_CONNECT auth values appear to be placeholders"
  else
    ok "APP_STORE_CONNECT_KEY and APP_STORE_CONNECT_ISSUER are set"
  fi
fi

if [[ -n "$APP_STORE_CONNECT_KEY" ]]; then
  key_file="$KEY_FILE_DIR/AuthKey_${APP_STORE_CONNECT_KEY}.p8"
  if [[ -f "$key_file" ]]; then
    ok "Found App Store key file: $key_file"
  else
    warn "Expected key file not found: $key_file"
  fi
fi

print_header "App Review Risk Checks"
if [[ -f "$INFO_PLIST" ]]; then
  if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "$INFO_PLIST" 2>/dev/null | grep -Eq "bluetooth-central|bluetooth-peripheral|audio"; then
    fail "Info.plist includes unsupported background modes (bluetooth/audio)"
  else
    ok "Info.plist background modes limited to required capabilities"
  fi
else
  warn "Info.plist not found at $INFO_PLIST"
fi

if grep -Fq "replace with active reviewer support line" "$PACKET_PATH"; then
  fail "Reviewer phone contact is still a placeholder"
else
  ok "Reviewer phone contact appears finalized"
fi

print_header "Summary"
if (( errors == 0 )); then
  echo -e "${GREEN}Preflight PASSED${NC}"
else
  echo -e "${RED}Preflight FAILED${NC}"
fi

echo "Errors: $errors"
echo "Warnings: $warnings"

if (( errors > 0 )); then
  exit 1
fi
