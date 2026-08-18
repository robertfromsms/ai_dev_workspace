# Workspace MCP layout

## Contents

- [Control-plane boundary](#control-plane-boundary)
- [Architecture](#architecture)
- [Files and responsibilities](#files-and-responsibilities)
- [Staged change bundle](#staged-change-bundle)
- [Local package checklist](#local-package-checklist)
- [`servers.json` pattern](#serversjson-pattern)
- [Runtime adapters](#runtime-adapters)
- [Secret pattern for a local MCP](#secret-pattern-for-a-local-mcp)
- [When Compose changes are justified](#when-compose-changes-are-justified)
- [Post-install validation commands](#post-install-validation-commands)

## Control-plane boundary

The directories that define the AI-development environment are a protected control plane. Agents may inspect them and prepare proposed changes, but the user applies those changes outside the development container. This includes `mcp/`, `.codex/`, `.devcontainer/`, `hook_scripts/`, and the future read-only `skills/` directory.

Stage AI-dev changes under `/workspace/.project-tmp`; it is writable and ignored by Git. Do not weaken a Docker mount, filesystem permission, runtime sandbox, or approval policy to edit a protected target. These restrictions do not apply to the eventual project source, which is the agent's normal working area.

## Architecture

Local MCP traffic follows this path:

```text
agentic runtime
  -> http://mcp_gateway:8080/servers/<server-id>/mcp
  -> mcp-proxy
  -> one locally installed stdio MCP process
```

Remote MCP traffic bypasses the gateway:

```text
agentic runtime -> verified HTTPS MCP endpoint
```

"Install locally" means installing in the `mcp_gateway` image, not in the AI development container and not in every agentic runtime.

## Files and responsibilities

- `mcp/Dockerfile.mcp`: installs and pins local MCP packages and their runtimes.
- `mcp/servers.json`: gives `mcp-proxy` named stdio commands, arguments, and non-secret environment values.
- `mcp/compose.mcp-gateway.yml`: creates the gateway, private backends, mounts, tmpfs paths, and Docker secrets.
- `mcp/docker-mcp-gateway-entrypoint.sh`: shared gateway startup only; avoid MCP-specific logic here.
- `mcp/.env`: local Compose variable values. Secret variables contain external secret-file paths, never credential values.
- `mcp/.env.tmpl`: committed list of supported variables with blank values.
- `.codex/config.toml`: Codex's runtime adapter. Other runtimes need their own documented adapters.

The current gateway image is Node on Debian with Python available. Python MCP packages live in `/opt/mcp-python`; Node MCP packages are installed globally. The runtime process is UID/GID `1000`, the root filesystem is read-only, and writable space is limited to tmpfs-backed `/tmp` and `/home/node`.

## Staged change bundle

Use this layout for an approved proposal:

```text
.project-tmp/install-mcp/<server-id>/
├── APPLY.md
├── files/
│   ├── mcp/Dockerfile.mcp
│   ├── mcp/servers.json
│   └── .codex/config.toml
└── change.patch
```

Include only files required by the chosen mode. A remote MCP normally needs runtime configuration candidates only. A keyless local MCP normally needs the Dockerfile, `servers.json`, and runtime candidates, with no Compose or entrypoint candidate.

`APPLY.md` is the user's handoff manifest. Include source checksums, candidate destinations, manual steps, validation evidence, user-run commands, and rollback instructions. Candidate files must be complete and based on the latest protected originals. Never include `mcp/.env`, secret values, private host secret paths, or unrelated workspace files.

## Local package checklist

Require all of the following before recommending the simple local path:

- a documented stdio transport
- a deterministic startup command that stays in the foreground
- compatibility with the gateway's Node/Python/system versions
- compatibility with the pinned Python MCP SDK when installed in `/opt/mcp-python`
- no root privileges, Docker socket, host networking, or persistent writable filesystem
- no separate daemon unless explicitly approved
- acceptable license, provenance, maintenance, and dependency risk

Use an exact version argument near the other package version arguments in the staged `Dockerfile.mcp` candidate. Extend an existing package-manager install layer when practical, but do not combine packages in a way that obscures dependency conflicts.

## `servers.json` pattern

Use a stable lower-snake-case server ID and an absolute executable path when known:

```json
{
  "mcpServers": {
    "example_server": {
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

Adapt only documented flags. Do not assume every MCP accepts `--transport stdio`. Do not put secret values or external secret-file paths in this committed file.

## Runtime adapters

### Codex

For a local gateway server, use the named proxy endpoint:

```toml
[mcp_servers.example_server]
url = "http://mcp_gateway:8080/servers/example_server/mcp"
enabled = false
required = false
default_tools_approval_mode = "auto"
startup_timeout_sec = 20
tool_timeout_sec = 60
```

For a remote server, replace `url` with the verified HTTPS endpoint and do not add gateway files.

Start conservatively. Discover the actual tool names, review their behavior and annotations, then add an `enabled_tools` allowlist and choose the approval mode deliberately. Enable the runtime block only when the user wants the MCP active.

### Other runtimes

Locate the runtime's project or user MCP configuration and consult its current official schema. Record whether it supports Streamable HTTP, custom headers, OAuth, secret-file references, tool allowlists, and per-tool approvals. Do not use hook session identifiers to choose a configuration format.

If several runtime configurations exist, distinguish between:

- the runtime currently executing the skill
- runtimes installed in the repository
- runtimes the user explicitly wants updated

Only the last category determines the required edit set.

## Secret pattern for a local MCP

Only use this when the MCP cannot be keyless.

`mcp/.env.tmpl`:

```dotenv
EXAMPLE_API_KEY_FILE=
```

The user's uncommitted `mcp/.env` points to a secret file outside the repository:

```dotenv
EXAMPLE_API_KEY_FILE=/external/private/path/example_api_key
```

Compose service mount:

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

Point a native key-file option at `/run/secrets/example_api_key`. If the MCP only accepts an environment variable, use an MCP-specific wrapper installed in the image that reads this file and immediately `exec`s that server. Never echo the value, pass it as a command-line argument, or export it from the shared gateway entrypoint.

For a remote MCP, use the runtime's secure authentication mechanism. Do not route a remote credential through the local gateway solely to reuse Docker secrets unless the user explicitly approves that architecture.

## When Compose changes are justified

Compose should remain unchanged for:

- a keyless stdio MCP installed in the gateway
- a remote MCP configured directly in a runtime
- ordinary command, argument, or non-secret environment changes handled by `servers.json`

Compose changes are justified only for:

- a required Docker secret mount
- an unavoidable separate backend service
- a required tmpfs or other tightly scoped runtime resource that cannot be handled by the existing gateway

Avoid changing the shared entrypoint. Prefer static image installation, `servers.json`, native secret-file flags, or a per-MCP wrapper.

## Post-install validation commands

Record the applicable commands in `APPLY.md` for the user to run after manually installing the candidate files:

```bash
jq empty mcp/servers.json
docker compose -f mcp/compose.mcp-gateway.yml config
docker compose -f mcp/compose.mcp-gateway.yml build mcp_gateway
docker compose -f mcp/compose.mcp-gateway.yml up -d mcp_gateway
docker compose -f mcp/compose.mcp-gateway.yml logs --no-color mcp_gateway
```

Add `--env-file mcp/.env` only when that user-managed file exists and its path variables are needed. Do not create a fake populated `.env` to make validation pass. If no API keys are needed, the repository's `blank_secret` fallback may be sufficient. After the gateway is healthy, verify tool discovery and make a benign call through every runtime adapter changed by the installation. Treat all these checks as pending until the user reports or the agent observes their actual results.
