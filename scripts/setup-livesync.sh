#!/usr/bin/env bash
set -euo pipefail

read -r -p "LiveSync setup URI: " SETUP_URI
read -r -s -p "LiveSync setup URI passphrase: " SETUP_PASSPHRASE
printf '\n'

export SETUP_URI

printf '%s\n' "$SETUP_PASSPHRASE" \
  | docker compose run --rm -T \
      --entrypoint /bin/sh \
      -e SETUP_URI \
      livesync-cli \
      -c 'node /app/dist/index.cjs /vault setup "$SETUP_URI"'

unset SETUP_URI SETUP_PASSPHRASE

docker compose run --rm -T \
  --entrypoint /bin/sh \
  livesync-cli \
  -c 'node -e '\''const fs=require("fs"); const s=JSON.parse(fs.readFileSync("/vault/.livesync/settings.json","utf8")); const ok=s.isConfigured && s.couchDB_URI && s.couchDB_USER && s.couchDB_PASSWORD && s.couchDB_DBNAME; console.log(ok ? "LiveSync settings configured" : "LiveSync settings are still incomplete"); process.exit(ok ? 0 : 1);'\'''

docker compose restart livesync-cli
