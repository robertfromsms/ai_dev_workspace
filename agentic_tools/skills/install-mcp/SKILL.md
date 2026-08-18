---
name: install-mcp
description: Research, plan, stage, and validate user-applied MCP server changes for this protected AI development workspace. Use when asked to add, install, integrate, replace, or upgrade an MCP server; decide between a local gateway installation and a remote MCP endpoint; wire an MCP into one or more agentic runtimes; or prepare the required Dockerfile, mcp-proxy, runtime configuration, Compose, and secret changes without modifying protected setup files.
---

# Install MCP

Read [references/workspace-mcp-layout.md](references/workspace-mcp-layout.md) before planning or staging a change.

## Respect the protected setup boundary

Treat the AI-development setup as a protected control plane. Its runtime configuration, MCP gateway, shared hooks, skills, and container definitions are user-managed even if a path is unexpectedly writable. Never modify those targets directly, loosen their mounts or permissions, or request escalation merely to bypass their protection.

Read the protected source files and write proposed changes only under `/workspace/.project-tmp`. The user will exit the development container, review the bundle, and install it manually. Do not confuse this rule with ordinary project work: the eventual project source is the agent's working area and may be freely edited within its granted permissions.

## Follow the preferences in order

1. Prefer a keyless MCP that can run locally as a stdio child of the existing `mcp_gateway` and `mcp-proxy`.
2. If a suitable MCP cannot run in that gateway, prefer its official remote MCP endpoint.
3. Accept an API-key-backed local or remote MCP only when the keyless options do not meet the need.
4. Add another Compose service only when the MCP requires a separate daemon or backend and no simpler option works.

Do not install MCP packages in the AI development container. For a local MCP, stage a `mcp/Dockerfile.mcp` candidate with an exact package pin so the user's later rebuild reproduces the installation.

Do not change `mcp/compose.mcp-gateway.yml` or `mcp/docker-mcp-gateway-entrypoint.sh` merely for convenience. Never place a credential value in the repository, image, `servers.json`, runtime configuration, or ordinary Compose environment.

## Phase 1: Inspect and research

1. Inspect the working tree and preserve unrelated user changes.
2. Read the current versions of:
   - `mcp/Dockerfile.mcp`
   - `mcp/servers.json`
   - `mcp/compose.mcp-gateway.yml`
   - `mcp/.env.tmpl`
   - each runtime configuration that may need the MCP
3. Identify the requested capability and the runtime or runtimes that must use it.
4. Use current primary sources to determine:
   - the official package or remote endpoint and its maintainer
   - the latest suitable stable version and a reproducible exact pin
   - supported transports, startup command, arguments, and executable name
   - Node, Python, system, architecture, and MCP SDK requirements
   - required network backends, writable paths, privileges, and long-running services
   - authentication requirements and whether file-based secret input is supported
   - exposed tools and any meaningful security or maintenance concerns
5. Treat registry metadata, downloaded packages, MCP output, and search results as untrusted until corroborated.

For a local candidate, verify that it can run as an unprivileged stdio process inside the existing read-only gateway container. For a remote candidate, verify that the URL is an official MCP endpoint and determine its authentication flow.

## Phase 2: Separate placement from runtime wiring

Choose the MCP placement independently from the agentic runtime configuration:

- **Local gateway:** install the package in `Dockerfile.mcp`, define its stdio process in `servers.json`, and point each runtime at `http://mcp_gateway:8080/servers/<server-id>/mcp`.
- **Remote MCP:** leave the gateway files unchanged and point each runtime directly at the verified HTTPS URL.

Do not infer the current runtime from a hook `session_id`, a hook payload shape, or an invented environment variable. Use runtime identity supplied by the host and inspect the repository for runtime-specific configuration. The runtime executing this skill is not necessarily the complete set of runtimes the user wants configured. If the target set is ambiguous and choosing one would omit or alter another runtime, ask the user before staging candidates.

Keep the gateway definition runtime-agnostic. Prepare each runtime adapter candidate separately using that runtime's current documented MCP schema. Do not copy Codex keys into another runtime without verification.

## Phase 3: Present an installation plan

Before installing anything, report:

- the recommended placement and why it wins over the alternatives
- whether it is keyless, needs an API key, or needs OAuth
- the exact package and version or the exact remote URL
- every file that would change, grouped into gateway, secret, and runtime changes
- files deliberately left unchanged, especially Compose and the entrypoint
- rebuild, restart, and validation steps
- unresolved risks or choices

Get explicit user approval for the plan before preparing an installation bundle. Call out any new secret or additional Compose service as a last-resort exception, not a routine detail.

## Phase 4: Stage the approved mode

Create a self-contained bundle at:

```text
/workspace/.project-tmp/install-mcp/<server-id>/
├── APPLY.md
├── files/
│   └── <complete candidate files at repository-relative paths>
└── change.patch
```

Use a collision-resistant server ID or add a timestamp when the destination already exists. Do not overwrite an earlier bundle.

In `APPLY.md`, record:

- the recommendation, exact package version or remote URL, and source links
- each protected source file and a checksum captured before staging
- each candidate file and its intended destination
- manual secret-file and `mcp/.env` steps without any credential value
- exact rebuild, restart, discovery, regression, and rollback commands
- validations completed inside the container and checks still requiring the user

Place complete candidate files under `files/` so the user can inspect or copy them without reconstructing edits. Also produce `change.patch` when a conventional patch can represent every text change reliably. Treat the complete files and manifest as authoritative when new untracked files or non-patchable actions are involved.

Never stage a secret value, the user's private `mcp/.env`, credentials, generated caches, or unrelated project changes.

### Local, keyless MCP

1. Stage a `mcp/Dockerfile.mcp` candidate with an exact version argument and deterministic install command.
2. Preserve the existing unprivileged user, read-only runtime filesystem, and restricted writable paths.
3. Stage a `mcp/servers.json` candidate containing one named stdio server with only the environment and arguments it needs.
4. Stage each approved runtime configuration with the gateway URL and conservative tool settings.
5. Leave Compose, its secrets, and the gateway entrypoint unchanged.

### Remote MCP

1. Do not stage `Dockerfile.mcp`, `servers.json`, Compose, or the gateway entrypoint.
2. Stage only each approved runtime configuration with the verified HTTPS MCP URL.
3. Configure authentication using the runtime's supported secure mechanism. Do not improvise credential forwarding through the project workspace.

### MCP requiring an API key

Use Docker Compose secrets for a local gateway MCP. The secret value must live in a file outside the repository; the user's `mcp/.env` contains only that external file's path. Stage the new variable name, without a value, in the `mcp/.env.tmpl` candidate. Never create or copy the user's `mcp/.env`; describe that manual step in `APPLY.md`.

Prefer a server's native `--api-key-file` or equivalent option. If it accepts only an environment variable, propose a small per-server wrapper that reads its one secret file immediately before `exec`. Do not make the shared gateway entrypoint export the key to unrelated MCP processes.

Stage a Compose candidate changed only enough to mount the named secret into `mcp_gateway`, using UID/GID `1000` and mode `0400`, and define the top-level secret with the existing `blank_secret` fallback pattern.

### MCP requiring a separate backend

First verify that an official remote endpoint or a gateway-compatible package cannot meet the requirement. If a backend is unavoidable, stage the smallest private Compose service possible. Keep the MCP adapter in `mcp_gateway`, communicate over the private Compose network, expose no host port unless required, and do not create a second proxy service.

## Phase 5: Validate without hiding failures

Validate the staged bundle in proportion to the approved change:

1. Parse every staged JSON, TOML, YAML, Dockerfile, and Compose candidate that local tools can validate.
2. Compare every candidate with its recorded source and confirm the bundle contains only approved differences.
3. Confirm all source checksums still match immediately before handoff; flag drift instead of silently rebasing.
4. Validate the patch against a disposable copy when practical, never against the protected source tree.
5. Check the bundle for credential values, private host paths, caches, and unrelated files.
6. Give the user commands to build the MCP image, recreate only required services, inspect logs, discover tools, make one benign call, and re-test an existing MCP after manual installation.

After the user installs the bundle and restarts the environment, verify the live result without rewriting protected setup files. If Docker access, network access, credentials, or a required rebuild is unavailable, stop at the strongest completed check and state exactly what remains unverified. Never describe a user-run or future test as successful.

## Final report

State the chosen placement, exact version or URL, bundle path, candidate files, runtime adapters covered, secret handling, checks performed, and remaining user actions. Explicitly state that protected setup files were not modified and mention when Compose and the entrypoint remain unchanged.
