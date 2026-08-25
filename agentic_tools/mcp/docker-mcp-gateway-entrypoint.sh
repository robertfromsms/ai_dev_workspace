#!/bin/sh
set -eu

# this entrypoint may be useful in the future for other post starting mcp_gateway service
# but before starting the mcp-proxy

echo "mcp_gateway service started!"

# this is where other useful stuff can happen

echo "starting mcp-proxy..."

exec "$@"