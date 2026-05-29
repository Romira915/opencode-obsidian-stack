#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p \
  "$REPO_DIR/data/openchamber" \
  "$REPO_DIR/data/opencode/share" \
  "$REPO_DIR/data/opencode/state" \
  "$REPO_DIR/data/opencode/config/env" \
  "$REPO_DIR/data/ssh" \
  "$REPO_DIR/data/gh" \
  "$REPO_DIR/data/vault"

# OpenCode の opencode.json が参照する env ファイル群（値は後で手動入力）
touch "$REPO_DIR/data/opencode/config/env/google-oauth-client-id"
touch "$REPO_DIR/data/opencode/config/env/google-oauth-client-secret"
touch "$REPO_DIR/data/opencode/config/env/user-google-email"

if [ "$(id -u)" -eq 0 ]; then
  chown -R 1000:1000 "$REPO_DIR/data"
else
  chown -R 1000:1000 "$REPO_DIR/data" 2>/dev/null || true
fi

if ! [ -d /home/openchamber/workspaces ]; then
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/openchamber/workspaces
    chown 1000:1000 /home/openchamber/workspaces
  else
    echo "[warn] need sudo for /home/openchamber/workspaces"
    sudo mkdir -p /home/openchamber/workspaces
    sudo chown 1000:1000 /home/openchamber/workspaces
  fi
fi

echo "[done] data directories ready"
