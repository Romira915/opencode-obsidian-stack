#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$REPO_DIR/romira-s-config"

if [ ! -d "$CONFIG_DIR/.git" ]; then
  git clone git@github.com:Romira915/romira-s-config.git "$CONFIG_DIR"
else
  git -C "$CONFIG_DIR" pull
fi

echo "romira-s-config ready. Run: docker compose up -d"
