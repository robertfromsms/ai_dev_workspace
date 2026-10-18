# AI development workspace

From the point of view of the ai_dev_user, the ai_dev_agent and the mcp_gateway services, there are two separate repositories:

- `/workspace` is the AI development workspace: its tooling, configuration, and infrastructure.
- `/workspace/working_project` is the user's project. It is mounted from a separate host directory and is the project the user wants help with.

Starting in `/workspace` is intentional so the agentic runtimes can use the runtime configuration. Do not infer from the starting directory that `/workspace` is the application.

## Choosing where to work

- Unless the user explicitly asks for help to change the AI development workspace, make application changes under `/workspace/working_project`.
- Before working on the project, read any applicable instructions in its repository, including its own `AGENTS.md` and any working project's nested `AGENTS.md`.
- Set the working directory of application shell commands to `/workspace/working_project`. Use application-relative paths from there when practical.
- For application Git commands, use `git -C /workspace/working_project …`. An unqualified `git` command run from `/workspace` targets the workspace repository.
- Before relying on application Git state, check `git -C /workspace/working_project rev-parse --show-toplevel`. If it does not identify the application repository, stop and tell the user; Git may otherwise discover the workspace repository instead.
- Do not commit, push, or otherwise change either repository's Git state unless the user asks. Follow the application owner's Git rules; do not assume its `.git` has the same protections as the workspace's `.git`.
- The working project may not be using `git`. 

## Workspace and security boundaries

- Workspace configuration and infrastructure live under `/workspace`, including `.devcontainer`, `.codex`, `.opencode`, `.agents`, and `agentic_tools`. Change them only for a workspace-specific request.
- The containers, mounts, runtime permissions, and available tools intentionally limit what the agent can do. Do not bypass or weaken those controls to finish a task.
- If a necessary action is blocked or requires a host-side change, stop and explain what is blocked and what the user needs to do. Do not claim to have verified something that you could not verify.
- Do not expose credentials or copy secrets into source files, logs, or responses.

## Communication

Be direct and accurate. Do not flatter the user or agree merely to be agreeable. Point out mistakes, uncertainties, and tradeoffs clearly.