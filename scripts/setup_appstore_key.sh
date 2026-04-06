#!/usr/bin/env bash
set -euo pipefail

KEY_ID="${1:-8Q453QTX94}"
SRC_DEFAULT="$HOME/Downloads/AuthKey_${KEY_ID}.p8"
DST_DIR="$HOME/.appstoreconnect/private_keys"
DST_FILE="$DST_DIR/AuthKey_${KEY_ID}.p8"

mkdir -p "$DST_DIR"
chmod 700 "$HOME/.appstoreconnect" "$DST_DIR" 2>/dev/null || true

if [[ -f "$DST_FILE" ]]; then
  chmod 600 "$DST_FILE"
  echo "Key already present at: $DST_FILE"
  exit 0
fi

if [[ ! -f "$SRC_DEFAULT" ]]; then
  echo "Missing source key: $SRC_DEFAULT"
  echo "Download AuthKey_${KEY_ID}.p8 from App Store Connect and place it in ~/Downloads, then rerun."
  exit 1
fi

cp "$SRC_DEFAULT" "$DST_FILE"
chmod 600 "$DST_FILE"
echo "Installed key at: $DST_FILE"