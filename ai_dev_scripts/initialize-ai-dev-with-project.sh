#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

source "${script_dir}/common-with-project.sh"

manifest_file="${script_dir}/ai-dev-manifest.json"

project_root="$(get_value_from_manifest '.project_root' "$manifest_file")"
env_file="$(get_value_from_manifest '.env_file' "$manifest_file")"
bridge_file="${project_root}/$(get_value_from_manifest '.paths.compose_ai_dev_project_bridge' "$manifest_file")"
ai_dev_warm_devcontainer="${project_root}/$(get_value_from_manifest '.paths.ai_dev_warm_devcontainer' "$manifest_file")"

declare -a validated_files_to_use=()
project_primary_service_to_use=""

validate_with_project_envs \
    "$env_file" \
    "$project_root" \
    validated_files_to_use \
    project_primary_service_to_use

prepare_project_bridge \
    "$bridge_file" \
    validated_files_to_use \
    "$project_primary_service_to_use"

prepare_warm_hot_devcontainer \
    "$ai_dev_warm_devcontainer" \
    "$project_primary_service_to_use"

validate_warm_hot_devcontainer \
    "$ai_dev_warm_devcontainer" \
    "$project_primary_service_to_use"

printf 'AI Dev project initialization completed successfully.\n'