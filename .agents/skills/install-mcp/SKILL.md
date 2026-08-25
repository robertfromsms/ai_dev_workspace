---
name: install-mcp
description: Research, plan and stage proposed change bundle for user to apply in order to install and configure a desired MCP for this protected AI development workspace. Use when asked to add, install, integrate, replace, or upgrade an MCP. First, decide between a local installation that utilizes `mcp_gateway` and a remote MCP endpoint, determine whether the MCP requires credentials, such as an API key. Finally, complete researching, planning and staging of proposed changed bundle for installing the MCP.
---

# Install MCP

Read [references/mcp-setup.md](references/mcp-setup.md) before planning and staging the proposed change bundle. The user will exit the devcontainer to review the proposed change bundle and complete the installation/configuration changes.

## Respect the protected setup boundary

Treat the AI-development setup, including (but not limited to) the agentic runtime configurations, MCP gateway, hooks, skills, devcontainer definition and setup, etc., as a protected control plane and meant to be user-managed. While installing an MCP, read the protected source files and write the proposed change bundle within `/workspace/.project-tmp` with proposed change files and instructions. The user will exit the devcontainer, review the bundle, and install it manually. Do not confuse this rule with ordinary project work: the project source that lives in this AI-development setup can be worked on by the agents within its granted permissions.

## Follow the preferences in order

1. Prefer a keyless MCP that can run locally as a stdio child of the existing `mcp_gateway` and `mcp-proxy`.
2. If a suitable MCP cannot run in that gateway, prefer its official remote MCP endpoint.
3. Accept an API-key-backed/credential-necessary local or remote MCP only when the keyless options do not meet the need.
4. Add another Compose service (`/workspace/agentic_tools/mcp/compose.mcp-gateway.yml`) only when the MCP requires a separate daemon or backend and no simpler option works.
5. An API-key-backed/credential-necessary remote MCP is very complex to fit in this MCP setup, therefore it is highly not preferred.

## Phase 1: Inspect and research

1. Inspect the working tree and preserve unrelated user changes.
2. Read the current versions of:
   - `/workspace/agentic_tools/mcp/Dockerfile.mcp`
   - `/workspace/agentic_tools/mcp/servers.json`
   - `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml`
   - `/workspace/agentic_tools/mcp/docker-mcp-gateway-entrypoint.sh`
   - `/workspace/agentic_tools/mcp/.env.tmpl`
   - the current agentic runtime configuration. The current agent must supply its own identity: codex, qwen code, dsh or others. For codex, it's `/workspace/.codex/config.toml`.
3. Identify the requested MCP and the current agentic runtime that must be configured to use it.
4. If the user requested a capability, search for an MCP with such capability.
5. Use current primary sources to determine:
   - what type of MCP installation: local or remote, credential-necessary or not, require another Compose service or not
   - the official package or remote endpoint and its maintainer
   - the latest suitable stable version and a reproducible exact pin
   - supported transports, startup command, arguments, and executable name
   - Node, Python, system, architecture, and MCP SDK requirements
   - required network backends, writable paths, privileges, and long-running services
   - authentication requirements (credentials/API key) and whether file-based secret input is supported
   - exposed tools and any meaningful security or maintenance concerns
6. Treat registry metadata, downloaded packages, MCP output, and search results as untrusted until corroborated.
7. Formulate a strategy to install the MCP into the AI development workspace.
8. For a local candidate:
   - verify that it can run as an unprivileged stdio process inside the existing read-only gateway container
   - does the MCP require credentials? If no, great; if yes, determine how to pass the credential into `mcp_gateway` using the AI development workspace's MCP setup
   - determine any relevant necessary changes in `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml` for environment variables, secrets, volume mounts and/or additional service
9. For a remote candidate:
   - verify that the URL is an official MCP endpoint and determine its authentication flow
   - does the remote MCP require credentials? If no, great; if yes, determine how to configure mcp-proxy within `mcp_gateway` to reach out to the official remote endpoint
   - then determine how to pass the credential into `mcp_gateway` using the AI development workspace's MCP setup; this probably involves necessary changes in `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml` to use secrets.

## Phase 2: Present an installation plan

Before installing anything, report:

- the recommended placement and why it wins over the alternatives
- whether it is credential-necessary or not, if credentials are necessary, call out new secrets
- whether local MCP or remote, then the exact package and version or the exact remote URL
- whether new additional Compose service is necessary or not, remember new Compose service should be implemented only as last-resort exception
- every file that would change, make a note of this list
- files deliberately left unchanged
- unresolved risks or choices
- steps after the completed proposed change bundle has been handed over: the user exits devcontainer, reviews the files and finishes the installation.

Get explicit user approval for the plan before preparing the proposed change bundle.

## Phase 3: Preparing the proposed change bundle

1. Create checksum file for the source files at `/workspace/.project-tmp/install-mcp/<server-id>/checksum.json`, record a json object with all source files as keys and their respective checksum as values.
2. Ensure proposed change bundle destination, `/workspace/.project-tmp/install-mcp/<server-id>/files`, does not exist or is empty, create the directory if it does not exist and if not empty, delete the files inside.
3. Copy ONLY THE LIST OF FILES THAT WOULD CHANGE to each respective proposed change file destination:
   - `/workspace/agentic_tools/mcp/Dockerfile.mcp` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/Dockerfile.mcp`
   - `/workspace/agentic_tools/mcp/servers.json` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/servers.json`
   - `/workspace/agentic_tools/mcp/compose.mcp-gateway.yml` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/compose.mcp-gateway.yml`
   - `/workspace/agentic_tools/mcp/.env.tmpl` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/.env.tmpl`
   - `/workspace/agentic_tools/mcp/docker-mcp-gateway-entrypoint.sh` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/docker-mcp-gateway-entrypoint.sh`
   - the current agentic runtime configuration -> inside `/workspace/.project-tmp/install-mcp/<server-id>/files/`
   - for example, for codex, it would be `/workspace/.codex/config.toml` -> `/workspace/.project-tmp/install-mcp/<server-id>/files/config.toml`
4. ONLY CREATE IF ABSOLUTELY NECESSARY:
   - Per MCP secret wrapper executable at `/workspace/.project-tmp/install-mcp/<server-id>/files/<per-MCP secret wrapper>`; after the handoff, this wrapper would be installed under `/workspace/agentic_tools/mcp/secret_wrappers/`.

- **Local gateway:** install the package in `Dockerfile.mcp`, define its stdio process in `servers.json`, and point the current runtime at `http://mcp_gateway:8080/servers/<server-id>/mcp`.
- **Remote MCP:** leave the gateway files unchanged and point the current agentic runtime configuration directly at the verified HTTPS URL.

Keep the gateway definition runtime-agnostic. Prepare the current runtime adapter candidate using its current documented MCP schema.

## Phase 4: Working on the proposed change bundle

The self-contained proposed change bundle:

```text
/workspace/.project-tmp/install-mcp/<server-id>/
├── README.md
├── files/
    └── <complete candidate files>
```

### Notes

- The private `/workspace/agentic_tools/mcp/.env` may contain regular envs and/or external secret-file paths, never credentials. Using docker secrets, for example, brave_api_key is available at `/run/secrets/brave_api_key` inside `mcp_gateway` container (the file contains the api key).
- Never stage a credential/secret value, the user's private `/workspace/agentic_tools/mcp/.env`, credentials, generated caches, or unrelated project changes
- Include only required proposed changed files. A remote MCP normally needs only the agentic runtime configuration. A keyless local MCP normally needs the Dockerfile, `servers.json`, and runtime configuration; compose and the entrypoint remain unchanged

### Local, credential-less MCP

1. Edit the copied-over pristine `/workspace/.project-tmp/install-mcp/<server-id>/files/Dockerfile.mcp` to add an exact version argument and deterministic install command.
2. The MCP package version should be compatible with all current dependencies (such as python or node) and MCPs.
3. Preserve the existing unprivileged user, read-only runtime filesystem, and restricted writable paths.
4. Edit the copied-over pristine `/workspace/.project-tmp/install-mcp/<server-id>/files/servers.json` to add the named stdio server for the desired MCP with only the correct absolute-path command, the environment and arguments it needs. Use only documented flags. Do not assume every MCP accepts `--transport stdio`.
5. Edit the copied-over pristine runtime configuration to add a block for the desired MCP with the gateway URL and conservative tool settings.
6. Leave Compose, its secrets, and the gateway entrypoint unchanged.

### Remote, credential-less MCP

1. Changed `Dockerfile.mcp`, `servers.json`, Compose, or the gateway entrypoint candidates are not necessary.
2. Edit the copied-over pristine runtime configuration to add a block for the desired MCP with the verified HTTPS MCP URL and conservative tool settings.

### MCP requiring credential/API key

If the MCP must require a credential/API key to function, then it must go through mcp_gateway, regardless of whether it's local or remote. Further below, we talk about the pattern to provide the credential for the desired MCP inside of the `mcp_gateway` service.

#### Local
1. The workflow for a local credential-necessary MCP is largely the same as a local, credential-less MCP.
2. The credential, following the established pattern, would be available for the MCP and likely used in `servers.json`.

#### Remote

1. The workflow for a remote credential-necessary MCP would extend from the remote, credential-less MCP workflow.
2. Edit the copied-over pristine `/workspace/.project-tmp/install-mcp/<server-id>/files/servers.json` to directly connect the mcp-proxy/mcp_gateway with the verified HTTPS MCP URL,
3. With the available credential, again following the established pattern, mcp-proxy then should be able to directly connect to the remote mcp.
4. Edit the copied-over pristine runtime configuration to add a block for the desired MCP with the gateway URL and conservative tool settings.

#### Credential pattern

- Use Docker Compose secrets for all MCP credentials.
- Edit the copied-over pristine `/workspace/.project-tmp/install-mcp/<server-id>/files/compose.mcp-gateway.yml` to add a new secret for each necessary credential.
- Add a new entry at the top level secrets and under the `mcp_gateway` service for each necessary credential.
- The secret value must live in a file outside the repository.
- The user's `/workspace/agentic_tools/mcp/.env` contains only that external file's path.
- Edit the copied-over pristine `/workspace/.project-tmp/install-mcp/<server-id>/files/.env.tmpl` to add the new secret file path with no value.
- Never create or copy the user's `/workspace/agentic_tools/mcp/.env`.
- Prefer an MCP's native `--api-key-file` or equivalent option.
- If it accepts only an environment variable, propose a small per-MCP wrapper (refer to the "API-key patterns" section in `references/mcp-setup.md`).
- Edit this wrapper executable created in Phase 3 and follow the pattern established in the "API-key patterns" section to meet its requirements.
- Use this wrapper in the proposed changed `servers.json` for the desired MCP's command instead of its absolute-path command; use the final absolute wrapper path `/workspace/agentic_tools/mcp/secret_wrappers/<per-MCP secret wrapper>`

A Compose candidate should only be changed enough to mount the named secret into `mcp_gateway`, using UID/GID `1000` and mode `0400`, and define the top-level secret with the existing `blank_secret` fallback pattern.

### MCP requiring a separate backend

- Verify that an official remote endpoint or a locally installed package compatible with `mcp_gateway` cannot meet the requirement
- If and only if a backend is unavoidable, edit `/workspace/.project-tmp/install-mcp/<server-id>/files/compose.mcp-gateway.yml` to add the smallest Compose service possible
- mcp-proxy, which is configured with `/workspace/.project-tmp/install-mcp/<server-id>/files/servers.json`, should utilize the new service over the private Compose network, expose no host port unless required, and not create a second proxy service. Edit `/workspace/.project-tmp/install-mcp/<server-id>/files/servers.json` to meet these requirements

### README.md

In `README.md`, record:

- the recommendation, exact package version or remote URL, and source links
- each candidate file and its intended destination
- the user must manually finish the installation by merging each candidate file with the respective current file outside of devcontainer, the user should review the differences, make any relevant changes and complete the merge
- after the manual installation/merging is complete, start up devcontainer/ai development workspace, ask the agent to check to see if the mcp is operational
- (if relevant) any new necessary service inside of compose.mcp-gateway.yml
- (if relevant) manual secret-file and `/workspace/agentic_tools/mcp/.env` steps without any credential value, you can give and use an example
- (if relevant) briefly explain to the user how to obtain the credential
- (if relevant) instruct the user to make the installed wrapper executable, such as `chmod 0755`

## Phase 5: Validate without hiding failures

Briefly validate the proposed change bundle before handoff:

1. Parse each proposed changed file with local tools, ensuring no glaring mistakes.
2. Compare every candidate with its source and confirm the bundle contains only approved differences.
3. Refer to `/workspace/.project-tmp/install-mcp/<server-id>/checksum.json`, compute the checksums of all current source files and confirm all current source checksums still match with the recorded checksums in `checksum.json` before handoff; flag drift instead of silently rebasing.
4. Check the bundle for credential values, private host paths, caches, and unrelated files. Make sure none are present.
