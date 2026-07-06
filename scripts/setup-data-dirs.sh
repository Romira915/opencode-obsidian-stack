#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a; source "$REPO_DIR/.env"; set +a
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

mkdir -p \
  "$REPO_DIR/data/openchamber" \
  "$REPO_DIR/data/opencode/share" \
  "$REPO_DIR/data/opencode/state" \
  "$REPO_DIR/data/opencode/config/env" \
  "$REPO_DIR/data/ssh" \
  "$REPO_DIR/data/gh" \
  "$REPO_DIR/data/vault" \
  "$REPO_DIR/data/google-workspace-mcp" \
  "$REPO_DIR/data/desktop-bypass-token"

# OpenChamber Desktop bypass 用の共有秘密 (nginx サイドカー X-Desktop-Token 判定)
# openssl を必須扱い、フォールバック処理は無し
command -v openssl >/dev/null 2>&1 || { echo "[setup] ERROR: openssl required to generate DESKTOP_BYPASS_TOKEN"; exit 1; }
if [ ! -s "$REPO_DIR/data/desktop-bypass-token/token" ]; then
    openssl rand -base64 32 > "$REPO_DIR/data/desktop-bypass-token/token"
    chmod 600 "$REPO_DIR/data/desktop-bypass-token/token"
    echo "[setup] generated data/desktop-bypass-token/token (chmod 600)"
else
    echo "[setup] reusing existing data/desktop-bypass-token/token (size=$(stat -c %s "$REPO_DIR/data/desktop-bypass-token/token"))"
fi

# OpenCode の opencode.json が参照する env ファイル群（値は後で手動入力）
touch "$REPO_DIR/data/opencode/config/env/google-oauth-client-id"
touch "$REPO_DIR/data/opencode/config/env/google-oauth-client-secret"
touch "$REPO_DIR/data/opencode/config/env/user-google-email"

if [ "$(id -u)" -eq 0 ]; then
  chown -R "$HOST_UID:$HOST_GID" "$REPO_DIR/data"
else
  chown -R "$HOST_UID:$HOST_GID" "$REPO_DIR/data" 2>/dev/null || true
fi

if ! [ -d /home/openchamber/workspaces ]; then
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/openchamber/workspaces
    chown "$HOST_UID:$HOST_GID" /home/openchamber/workspaces
  else
    echo "[warn] need sudo for /home/openchamber/workspaces"
    sudo mkdir -p /home/openchamber/workspaces
    sudo chown "$HOST_UID:$HOST_GID" /home/openchamber/workspaces
  fi
fi

echo "[done] data directories ready"
