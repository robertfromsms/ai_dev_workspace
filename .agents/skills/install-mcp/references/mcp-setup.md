# MCP Setup

## Contents

- [Files and responsibilities](#files-and-responsibilities)
- [Local and remote MCPs](#local-and-remote-mcps)
- [Proposed change bundle](#proposed-change-bundle)
- [`servers.json` pattern](#serversjson-pattern)
- [Agentic runtime configuration](#agentic-runtime-configuration)
- [API-key patterns](#api-key-patterns)

## Files and responsibilities

- `/workspace/agentic_tools/mcp/Dockerfile.mcp`: pin and install local MCP packages.
- `/workspace/agentic_tools/mcp/servers.json`: configure installed MCP, such as define named stdio processes, arguments, and non-secret environment values, for mcp-proxy in the mcp_gateway service.
- `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml`: configure the MCP docker services, such as mcp_gateway, required backends; useful configuration: secrets, volume mounts, envs, etc.
- `/workspace/agentic_tools/mcp/.env.tmpl`: list supported local variables with blank values.
- `/workspace/agentic_tools/mcp/docker-mcp-gateway-entrypoint.sh`: any potentially required startup command for the MCP, probably not necessary.
- Agentic runtime config file, for example `.codex/config.toml`: connect the active runtime to local (with mcp_gateway) or remote MCP endpoints using that runtime's documented schema.

## Local and remote MCPs
For a local MCP:

```text
agentic runtime
  -> http://mcp_gateway:8080/servers/<server-id>/mcp
  -> named stdio MCP process
```

A locally installed (in mcp_gateway) MCP would be configured in the agentic runtime configuration with its mcp_gateway url (plus other relevant said MCP configurations); the MCP package must have been installed in `/workspace/agentic_tools/mcp/Dockerfile.mcp`, the MCP must have been configured correctly to work with mcp-proxy inside the mcp_gateway service, that is `/workspace/agentic_tools/mcp/servers.json` always and `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml` and others very rarely. Usually, those rare MCP cases involves API keys.

For remote MCPs, the agentic runtime would be configured with the verified official url; no other MCP setup files requires changes. If the remote MCP requires an API key, while no MCP installation is involved, the key-necessary remote MCP would be configured to work through the mcp_gateway, then the agentic runtime would be configured with the corresponding mcp_gateway url.

For cases involving API keys, please refer to [API-key patterns](#api-key-patterns).

## Proposed change bundle

When planning and staging an MCP installation using the install-mcp skill, create the proposed changed files at:

```text
.project-tmp/install-mcp/<server-id>/
├── README.md
└── files/
    ├── Dockerfile.mcp
    ├── servers.json
    ├── compose.mcp-gateway.yml
    ├── .env.tmpl
    ├── docker-mcp-gateway-entrypoint.sh
    ├── <per-MCP secret wrapper>
    └── <agentic-runtime-config>
```

Proposed changed files must be complete and based on the latest source. At the end, instruct the user to review the proposed changed files and complete the installation outside of the devcontainer.

## `servers.json` pattern

This is an example of the json configuration in `servers.json`; mcpServers points to a json object with key (MCP name/id) and value (configuration for that MCP) pairs. The MCP name/id uses stable lower-snake-case convention, and the MCP configuration should include all relevant and documented fields/flags, including corresponding absolute executable path when known. This file does not ever include raw and exposed credentials.

```json
{
  "mcpServers": {
    "example_mcp": {
      "enabled": true,
      "command": "/usr/local/bin/example-mcp",
      "args": ["--transport", "stdio"],
      "env": {
        "HOME": "/home/node",
        "PATH": "/opt/mcp-python/bin:/usr/local/bin:/usr/bin:/bin",
        "TMPDIR": "/tmp",
        "XDG_CACHE_HOME": "/tmp/cache"
      }
    }
  }
}
```

## Agentic runtime configuration

When using the install-mcp skill, the current running agent shall supply the agentic runtime identity, and the proposed change agentic runtime configuration would be to update its configuration for the MCP integration using the documented schema/fields/flags.

### Codex example

For a local gateway MCP:

```toml
[mcp_servers.example_mcp]
url = "http://mcp_gateway:8080/servers/example_mcp/mcp"
enabled = false
required = false
default_tools_approval_mode = "auto"
startup_timeout_sec = 20
tool_timeout_sec = 60
```

## API-key patterns

Use this only when a credential/API key is absolutely necessary. Credentials, API keys and files containing them must remain outside the workspace. The .env.tmpl is a template.

`/workspace/agentic_tools/mcp/.env.tmpl`:

```dotenv
EXAMPLE_API_KEY_FILE=
```

The user's private `/workspace/agentic_tools/mcp/.env` contains only the credential file absolute path on the host. The external file contains the credential. Again, the credential file must be outside of the workspace.

```dotenv
EXAMPLE_API_KEY_FILE=/external/private/path/example_api_key
```

Compose mounts the file into the gateway:

```yaml
services:
  mcp_gateway:
    secrets:
      - source: example_api_key
        target: example_api_key
        uid: "1000"
        gid: "1000"
        mode: "0400"

secrets:
  example_api_key:
    file: ${EXAMPLE_API_KEY_FILE:-./blank_secret}
```

The MCP requiring the API key would utilize the key by the native key-file option at `/run/secrets/example_api_key`, such as `--brave-api-key-file /run/secrets/brave_api_key`.

If the MCP accepts only an environment variable, use a MCP-specific wrapper that reads the file and immediately `exec`s the server. `servers.json` would use this wrapper directly as opposed to using the absolute-path command. The following is the gist of a wrapper-script that may be necessary:

```bash
#!/bin/sh
set -eu

BRAVE_API_KEY="$(cat /run/secrets/brave_api_key)"
export BRAVE_API_KEY

exec /usr/local/bin/brave-search-mcp-server "$@"
```

For a remote MCP that requires an API key, the API key is available in the mcp_gateway service just like before. `servers.json` is configured to work with the verified official url; additional local installation may not be necessary. The key-necessary remote MCP would be available to the agentic runtime through the mcp_gateway. This case is comparatively more complicated and may require several iterations, including manually by the user, to get working.
