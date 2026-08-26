#!/bin/sh
set -eu

echo "mcp_gateway service started!"

# this is for checking and initializing codegraph indexing the project the first time
# dont worry about sync, that just happens.
codegraph_project="/workspace"
codegraph_dir="${codegraph_project}/.codegraph"
codegraph_db="${codegraph_dir}/codegraph.db"

if [ ! -f "$codegraph_db" ]; then
    if [ ! -w "$codegraph_dir" ]; then
        echo "CodeGraph index directory is not writable: $codegraph_dir" >&2
        exit 1
    fi

    echo "CodeGraph index not found; initializing..."
    DO_NOT_TRACK=1 /usr/local/bin/codegraph init "$codegraph_project"
else
    echo "Reusing existing CodeGraph index."
fi

echo "starting mcp-proxy..."

exec "$@"