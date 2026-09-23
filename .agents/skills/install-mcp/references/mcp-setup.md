# MCP Setup

## Contents

- [Files and responsibilities](#files-and-responsibilities)
- [Local and remote MCPs](#local-and-remote-mcps)
- [Proposed change bundle](#proposed-change-bundle)
- [`servers.json` pattern](#serversjson-pattern)
- [Agentic runtime configuration](#agentic-runtime-configuration)
- [API-key patterns](#api-key-patterns)
- [Credentialed remote MCP](#credentialed-remote-mcp)

## Files and responsibilities

- `/workspace/agentic_tools/mcp/Dockerfile.mcp`: pin and install local MCP packages.
- `/workspace/agentic_tools/mcp/servers.json`: configure installed MCP, such as define named stdio processes, arguments, and non-secret environment values, for mcp-proxy in the mcp_gateway service.
- `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml`: configure the MCP docker services, such as mcp_gateway, required backends; useful configuration: secrets, volume mounts, envs, etc.
- `/workspace/agentic_tools/mcp/.env.tmpl`: list supported local variables with blank values.
- `/workspace/agentic_tools/mcp/docker-mcp-gateway-entrypoint.sh`: any potentially required startup command for the MCP, probably not necessary.
- Agentic runtime config file, for example `/workspace/.codex/config.toml` and `/workspace/.opencode/opencode.jsonc`: connect the active runtime to local (with mcp_gateway) or remote MCP endpoints using that runtime's documented schema.

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

### OpenCode example
(yikes might need to come back and clean this up)

For a local gateway MCP:

```jsonc
{
  "mcp": {
    "example_mcp": {
      "type": "remote",
      "url": "http://mcp_gateway:8080/servers/example_mcp/mcp",
      "enabled": false
    }
  }
}

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

### Credentialed remote MCP

A remote MCP cannot access a Docker secret file inside `mcp_gateway`. The secret file is local credential storage. A per-MCP wrapper converts its contents into an authentication input supported by the remote-client `mcp-proxy`.

For a remote MCP accepting `Authorization: Bearer <token>`:

```text
agentic runtime
  -> http://mcp_gateway:8080/servers/<server-id>/mcp
  -> outer mcp-proxy named server
  -> per-MCP wrapper over stdio
  -> child mcp-proxy remote client
  -> verified HTTPS remote MCP
```

The wrapper reads the Docker secret and immediately replaces itself with the remote-client proxy:

```sh
#!/bin/sh
set -eu

secret_file="/run/secrets/example_remote_token"

if [ ! -r "$secret_file" ]; then
    echo "Required MCP credential file is not readable: $secret_file" >&2
    exit 1
fi

API_ACCESS_TOKEN="$(cat "$secret_file")"

if [ -z "$API_ACCESS_TOKEN" ]; then
    echo "Required MCP credential is empty" >&2
    exit 1
fi

export API_ACCESS_TOKEN

exec /opt/mcp-python/bin/mcp-proxy \
    --transport streamablehttp \
    https://example.com/mcp
```

Use the remote MCP's verified transport and official endpoint. Do not print ordinary output to stdout because stdout carries the MCP protocol. Do not use `set -x`, print the credential, or pass the bearer token through command arguments.

Configure the wrapper as the named stdio command in `servers.json`:

```json
{
  "mcpServers": {
    "example_remote": {
      "enabled": true,
      "command": "/workspace/agentic_tools/mcp/secret_wrappers/example-remote.sh",
      "args": [],
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

The runtime connects only to the gateway endpoint:

```text
http://mcp_gateway:8080/servers/example_remote/mcp
```

`mcp-proxy`'s named-server configuration treats the wrapper as a stdio MCP. Fields such as `transportType` do not configure the wrapper's outbound connection; the wrapper must pass the verified transport to the child `mcp-proxy`.

This pattern is suitable for static bearer tokens because `mcp-proxy` supports `API_ACCESS_TOKEN`. Other authentication schemes require separate evaluation:

- Custom headers require `--headers`; passing the credential as its value exposes it in process arguments.
- OAuth client credentials use CLI options that may likewise expose the client secret.
- Interactive OAuth cannot be implemented by merely reading a static Docker secret.
- Cookies, signed requests, and provider-specific authentication may require a purpose-built credential bridge.

Do not stage one of these alternatives unless current primary documentation establishes a credential-safe implementation.