# AI Development Workspace

This package adds a containerized AI-assisted development environment to an existing project.

The development container is intentionally separate from the application containers. Visual Studio Code/IntelliJ IDEA, Cline, terminals, and development tools run inside the `ai_dev` container, while the application continues to run in its own services.

## Supported editors

Cline is available for both:

* Visual Studio Code
* JetBrains IDEs, including IntelliJ IDEA

The Dev Container configurations included in this package are designed specifically for Visual Studio Code and the Dev Containers extension.

## Development environments

Two Dev Container configurations are provided.

### AI Development — Cold

The cold environment starts only the `ai_dev` development container.

Use this environment when you want to:

* edit or inspect the project;
* use Cline without starting the application stack;
* work on documentation or configuration;
* minimize resource usage.

### AI Development — Hot

The hot environment starts:

* the `ai_dev` development container;
* the application services defined by the app's Docker Compose config.

Use this environment when Cline or the developer needs to:

* run the application;
* execute tests that require supporting services;
* connect to databases, caches, or message brokers;
* validate changes against the complete development stack.

## Prerequisites

Install the following before using this workspace:

* Docker Desktop
* Visual Studio Code and/or IntelliJ IDEA
* Respective Dev Containers extension

## Installing into an existing project

From the root of the `ai_dev_skeleton` repository, run:

```powershell
.\ai_dev_install_scripts\install-ai-dev.ps1
```

The installer prompts for the full path of the target project.

Example:

```text
F:\projects\my_application
```

The target project directory must already exist.

The installer performs all conflict checks before copying files. It will stop without installing anything if one of the AI development resources already exists in the target project.

If PowerShell prevents the script from running, use:

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File .\ai_dev_install_scripts\install-ai-dev.ps1
```

### Files installed

The installer adds the following resources:

```text
.devcontainer/
├── Dockerfile
├── ai_dev/
│   └── devcontainer.json
└── ai_dev_hot/
    └── devcontainer.json

.vscode/
└── extensions.json

AI_DEV_WORKSPACE_README.md
compose.ai-dev.yml
vs_code_ai_dev_workspace.code-workspace
```

If `.devcontainer` or `.vscode` already exists, the installer preserves the existing directory.

If `.vscode/extensions.json` already exists, the installer merges the required extension recommendations into the existing `recommendations` array.

## Configure the Hot Dev Container

The hot Dev Container is intended to start both:

* the `ai_dev` development container; and
* the target project’s complete Docker Compose stack.

After installation, open:

```text
.devcontainer/ai_dev_hot/devcontainer.json
```

The initial configuration contains only the AI development Compose file:

```jsonc
"dockerComposeFile": [
  // Add the target project's real Compose file here.
  // "../../compose.yml",
  "../../compose.ai-dev.yml"
]
```

Uncomment or add the path to the target project’s main Compose file.

For example, if the project uses:

```text
compose.yml
```

at the project root, configure:

```jsonc
"dockerComposeFile": [
  "../../compose.yml",
  "../../compose.ai-dev.yml"
]
```

Paths in `dockerComposeFile` are resolved relative to:

```text
.devcontainer/ai_dev_hot/devcontainer.json
```

Because the configuration file is two directories below the project root, project-level Compose files normally begin with:

```text
../../
```

The order of the files matters. Put the application’s Compose file first and the AI development Compose file second:

```jsonc
"dockerComposeFile": [
  "../../compose.yml",
  "../../compose.ai-dev.yml"
]
```

Docker Compose will merge the files into one effective configuration. The application services come from the project Compose file, while the `ai_dev` service and its security configuration come from `compose.ai-dev.yml`.

After updating the file, run:

```text
Dev Containers: Rebuild and Reopen in Container
```

Then select:

```text
AI Development (Hot)
```

The cold configuration does not require the application Compose file. It starts only the `ai_dev` service.

## Opening the workspace

Open the installed workspace file:

```text
vs_code_ai_dev_workspace.code-workspace
```

You can open it from Visual Studio Code through:

```text
File → Open Workspace from File...
```

Then choose:

```text
vs_code_ai_dev_workspace.code-workspace
```

## Starting a Dev Container

After opening the workspace:

1. Press `Ctrl+Shift+P`.
2. Run `Dev Containers: Reopen in Container`.
3. Select one of the following:

   * `AI Development — Cold`
   * `AI Development — Hot`

Visual Studio Code will build or start the required containers, connect the window to the `ai_dev` container, and open the project at:

```text
/workspace
```

When the Dockerfile, Compose configuration, or Dev Container configuration changes, run:

```text
Dev Containers: Rebuild and Reopen in Container
```

## Leaving the Dev Container

Press `Ctrl+Shift+P` and run:

```text
Dev Containers: Reopen Folder Locally
```

Depending on the configured shutdown behavior, disconnecting from the Dev Container may leave its containers running.

They can be stopped through Docker Desktop or with Docker Compose.

## Windows and WSL prerequisite

On some Windows systems, the Dev Containers extension automatically attempts to mount a WSLg Wayland socket into the container.

This can cause an error similar to:

```text
accessing specified distro mount service:
stat /run/guest-services/distro-services/ubuntu.sock:
no such file or directory
```

The AI development container does not require Wayland or Linux graphical application support.

Disable the automatic Wayland socket mount in the local Visual Studio Code User Settings.

Open the Command Palette with `Ctrl+Shift+P`, then select:

```text
Preferences: Open User Settings (JSON)
```

Add:

```json
{
  "dev.containers.mountWaylandSocket": false
}
```

If the settings file already contains other properties, add the setting with the appropriate comma:

```json
{
  "files.autoSave": "afterDelay",
  "dev.containers.mountWaylandSocket": false
}
```

After changing the setting:

1. Save the file.
2. Run `Developer: Reload Window`.
3. Run `Dev Containers: Rebuild and Reopen in Container`.

This is a local Visual Studio Code setting and may need to be configured separately by each Windows developer.

## Filesystem isolation

The `ai_dev` container is configured so that the agent can write to:

```text
/workspace
/home/vscode
/tmp
```

These paths serve different purposes:

* `/workspace` is the target project mounted from the host.
* `/home/vscode` is a persistent Docker-managed home directory for Cline, Git, Visual Studio Code, and user configuration.
* `/tmp` is temporary storage that is discarded with the container.

The rest of the container filesystem is read-only.

The development container should not be given:

* privileged mode;
* the host Docker socket;
* the host user’s home directory;
* the host SSH directory;
* unrestricted host filesystem mounts.

## Git configuration

Inside the Dev Container, configure the Git identity with:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Because `/home/vscode` is persistent, this configuration survives container recreation.

If Git reports that `/workspace` has unsafe ownership, mark the known workspace mount as safe:

```bash
git config --global --add safe.directory /workspace
```

Do not use a wildcard such as:

```bash
git config --global --add safe.directory '*'
```

## Cline

Cline is installed inside the Dev Container rather than only on the host.

Its extension identifier is:

```text
saoudrizwan.claude-dev
```

Cline configuration and state are stored under:

```text
/home/vscode/.cline
```

Because `/home/vscode` uses persistent Docker-managed storage, Cline settings can survive Dev Container rebuilds.

Provider credentials should be narrowly scoped and should never be committed to the repository.