#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

source "${script_dir}/common.sh"

validate_with_project_envs
prepare_project_bridge
prepare_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_warm/devcontainer.json"
prepare_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_hot/devcontainer.json"
validate_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_warm/devcontainer.json"
validate_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_hot/devcontainer.json"

printf 'AI Dev project initialization completed successfully.\n'