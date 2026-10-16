#!/usr/bin/env bash
set -euo pipefail

if [ -f /workspace/.opencode/package.json ]; then
    bun install \
        --cwd /workspace/.opencode \
        --no-save
fi

exec "$@"