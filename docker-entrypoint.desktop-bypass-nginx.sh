#!/usr/bin/env bash
# Generates /etc/nginx/nginx.conf from the template, substituting secrets.
# Reads the shared secret from /run/secrets/desktop_bypass_token (mounted from
# data/desktop-bypass-token/token by docker-compose).
#
# Fails fast if the secret file is missing or empty (no fallback).

set -euo pipefail

SECRET_FILE="/run/secrets/desktop_bypass_token"

# -r test covers both "missing" and "unreadable" cases
if [ ! -r "$SECRET_FILE" ]; then
    echo "[desktop-bypass-nginx] ERROR: $SECRET_FILE not readable" >&2
    exit 1
fi

# Read secret (trailing newline stripped by read)
read -r DESKTOP_BYPASS_TOKEN < "$SECRET_FILE"
if [ -z "$DESKTOP_BYPASS_TOKEN" ]; then
    echo "[desktop-bypass-nginx] ERROR: $SECRET_FILE is empty" >&2
    exit 1
fi

export DESKTOP_BYPASS_TOKEN
export UPSTREAM_OAUTH2_PROXY
export UPSTREAM_OPENCHAMBER

envsubst '${DESKTOP_BYPASS_TOKEN} ${UPSTREAM_OAUTH2_PROXY} ${UPSTREAM_OPENCHAMBER}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "[desktop-bypass-nginx] config rendered, listening on :4181"
exec "$@"
