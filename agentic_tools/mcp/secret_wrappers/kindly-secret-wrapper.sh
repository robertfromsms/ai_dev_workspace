#!/bin/sh
set -eu

# hardcoding serply as the provider to use with kindly right now
SECRET_FILE="/run/secrets/serply_api_key"

if [ ! -f "$SECRET_FILE" ] || [ ! -r "$SECRET_FILE" ] || [ ! -s "$SECRET_FILE" ]; then
    echo "Kindly: Serply API key must be a readable, nonempty file" >&2
    exit 1
fi

export SERPLY_API_KEY="$(cat "$SECRET_FILE")"

exec /opt/kindly-python/bin/kindly-web-search-mcp-server "$@"
