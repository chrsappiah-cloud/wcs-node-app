#!/bin/bash
#
# validate_app_store_packet.sh
# Validates APP_STORE_SUBMISSION_PACKET.md for App Store submission readiness.
#
# Usage:
#   ./scripts/validate_app_store_packet.sh [path-to-packet]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PACKET_PATH="${1:-APP_STORE_SUBMISSION_PACKET.md}"

if [[ ! -f "$PACKET_PATH" ]]; then
  echo -e "${RED}ERROR:${NC} Packet file not found: $PACKET_PATH"
  exit 1
fi

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

# Extract the first non-empty line after a markdown heading.
extract_heading_value() {
  local heading="$1"
  awk -v h="$heading" '
    $0 == h {
      getline
      while (getline) {
        if ($0 !~ /^[[:space:]]*$/) {
          print $0
          exit
        }
      }
    }
  ' "$PACKET_PATH"
}

check_required_heading() {
  local heading="$1"
  if grep -Fq "$heading" "$PACKET_PATH"; then
    ok "Found section: $heading"
  else
    fail "Missing section: $heading"
  fi
}

check_char_limit() {
  local heading="$1"
  local limit="$2"
  local value
  value="$(extract_heading_value "$heading")"

  if [[ -z "$value" ]]; then
    fail "$heading has no value"
    return
  fi

  local len
  len=$(printf "%s" "$value" | wc -m | tr -d ' ')

  if (( len <= limit )); then
    ok "$heading length $len/$limit"
  else
    fail "$heading length $len exceeds limit $limit"
  fi
}

check_url_value() {
  local heading="$1"
  local value
  value="$(extract_heading_value "$heading")"

  if [[ -z "$value" ]]; then
    fail "$heading has no value"
    return
  fi

  if [[ "$value" =~ ^https:// ]]; then
    ok "$heading uses https URL"
  else
    fail "$heading must start with https:// (found: $value)"
  fi
}

print_header "Validating App Store Submission Packet"
echo "Packet: $PACKET_PATH"

print_header "Section Checks"
check_required_heading "## Upload Status"
check_required_heading "## Final Recommended Listing Copy"
check_required_heading "## Review Notes (Paste into App Review Information)"
check_required_heading "## One-Pass Submission Checklist"
check_required_heading "## Submission Form Answers (Draft)"

print_header "Field Limits"
check_char_limit "### Subtitle (30 chars max)" 30
check_char_limit "### Promotional Text (170 chars max)" 170
check_char_limit "### Keywords (100 chars max)" 100

print_header "URL Checks"
check_url_value "### Support URL"
check_url_value "### Marketing URL (optional)"
check_url_value "### Privacy Policy URL"

print_header "Quality Checks"
if grep -Eq '\[ADD|TODO|TBD|PLACEHOLDER' "$PACKET_PATH"; then
  fail "Found unresolved placeholder text"
else
  ok "No unresolved placeholder tokens found"
fi

if grep -Fq "Delivery UUID:" "$PACKET_PATH"; then
  ok "Delivery UUID is present"
else
  warn "Delivery UUID not found"
fi

if grep -Fq "Upload: SUCCEEDED" "$PACKET_PATH"; then
  ok "Upload success recorded"
else
  warn "Upload success status not explicitly recorded"
fi

print_header "Summary"
if (( errors == 0 )); then
  echo -e "${GREEN}Packet validation PASSED${NC}"
else
  echo -e "${RED}Packet validation FAILED${NC}"
fi

echo "Errors: $errors"
echo "Warnings: $warnings"

if (( errors > 0 )); then
  exit 1
fi
