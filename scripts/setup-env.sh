#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$REPO_DIR/.env" ]; then
  echo "[skip] .env already exists"
  exit 0
fi

cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
echo "[done] .env created — edit it before running setup.sh"
