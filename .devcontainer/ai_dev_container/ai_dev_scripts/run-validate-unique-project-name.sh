#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

source "${script_dir}/common-with-project.sh"

manifest_file="${script_dir}/ai-dev-manifest.json"

env_file="$(get_value_from_manifest '.env_file' "$manifest_file")"

validate_unique_project_name "$env_file"

printf 'AI Dev project name validation completed successfully.\n'