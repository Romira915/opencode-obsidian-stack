#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p \
  "$REPO_DIR/data/openchamber" \
  "$REPO_DIR/data/opencode/share" \
  "$REPO_DIR/data/opencode/state" \
  "$REPO_DIR/data/opencode/config" \
  "$REPO_DIR/data/ssh" \
  "$REPO_DIR/data/vault"

if [ "$(id -u)" -eq 0 ]; then
  chown -R 1000:1000 "$REPO_DIR/data"
else
  chown -R 1000:1000 "$REPO_DIR/data" 2>/dev/null || true
fi

echo "[done] data directories ready"
