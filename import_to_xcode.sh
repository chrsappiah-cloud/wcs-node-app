#!/bin/bash
# Wrapper for the Swift-based sync/import utility.
# Usage: ./import_to_xcode.sh [--project /path/to/GeoWCS.xcodeproj] [--source /path/to/src] [--target-root /path/to/GeoWCS] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_SCRIPT="$SCRIPT_DIR/import_to_xcode.swift"

if [ ! -f "$SWIFT_SCRIPT" ]; then
  echo "Error: missing $SWIFT_SCRIPT" >&2
  exit 1
fi

chmod +x "$SWIFT_SCRIPT"
exec "$SWIFT_SCRIPT" "$@"
