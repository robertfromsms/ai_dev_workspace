script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

source "${script_dir}/with_project/validate-with-project-envs.sh"
source "${script_dir}/with_project/prepare-project-bridge.sh"
source "${script_dir}/with_project/build-devcontainer-initializeCommand.sh"
source "${script_dir}/with_project/prepare-warm-hot-devcontainer.sh"
source "${script_dir}/with_project/validate-warm-hot-devcontainer.sh"