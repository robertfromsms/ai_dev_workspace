#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

project_root="/workspace"
env_file="${project_root}/.env"
bridge_file="${project_root}/compose.ai-dev-project-bridge.yml"

declare -a validated_files_to_use=()
project_primary_service_to_use=""

source "${script_dir}/common-with-project.sh"

validate_with_project_envs \
    "$env_file" \
    "$project_root" \
    validated_files_to_use \
    project_primary_service_to_use

prepare_project_bridge \
    "$bridge_file" \
    validated_files_to_use \
    "$project_primary_service_to_use"

validate_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_warm/devcontainer.json" \
    "$project_primary_service_to_use"

validate_warm_hot_devcontainer \
    "${project_root}/.devcontainer/ai_dev_hot/devcontainer.json" \
    "$project_primary_service_to_use"

printf 'AI Dev with project validation completed successfully.\n'