#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== (1/4) env ==="
"$SCRIPT_DIR/setup-env.sh"

echo "=== (2/4) data dirs ==="
"$SCRIPT_DIR/setup-data-dirs.sh"

echo "=== (3/4) opencode config ==="
"$SCRIPT_DIR/setup-config.sh"

echo "=== (4/4) livesync ==="
"$SCRIPT_DIR/setup-livesync.sh"

echo ""
echo "all setup done."
read -r -p "start stack? [Y/n] " answer
if [[ "${answer:-y}" =~ ^[Yy] ]]; then
  docker compose -f "$REPO_DIR/compose.yml" up -d
fi
