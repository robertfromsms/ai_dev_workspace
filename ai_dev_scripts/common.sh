fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

project_root="/workspace"
env_file="${project_root}/.env"
bridge_file="${project_root}/compose.ai-dev-project-bridge.yml"

source "${script_dir}/validate-with-project-envs.sh"
source "${script_dir}/prepare-project-bridge.sh"
source "${script_dir}/build-devcontainer-initializeCommand.sh"
source "${script_dir}/prepare-warm-hot-devcontainer.sh"
source "${script_dir}/validate-warm-hot-devcontainer.sh"