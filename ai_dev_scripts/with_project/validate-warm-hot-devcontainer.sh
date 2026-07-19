#!/usr/bin/env bash

validate_warm_hot_devcontainer() {
    local -r devcontainer_file="$1"
    local -r project_local_dev_service="$2"

    if [[ ! -f "$devcontainer_file" ]]; then
        fail \
            "Dev Container configuration does not exist: ${devcontainer_file}"
    fi

    if ! jq empty "$devcontainer_file" >/dev/null 2>&1; then
        fail \
            "Dev Container configuration is not valid strict JSON: ${devcontainer_file}"
    fi

    if ! jq -e '
        has("initializeCommand")
        and (.initializeCommand | type == "string")
    ' "$devcontainer_file" >/dev/null; then
        fail \
            "initializeCommand is missing or is not a string in: ${devcontainer_file}"
    fi

    local expected_command
    local actual_command

    expected_command="$(build_devcontainer_initialize_command "$project_local_dev_service")"

    actual_command="$(
        jq -r '.initializeCommand' "$devcontainer_file"
    )"

    if [[ "$actual_command" != "$expected_command" ]]; then
        printf 'ERROR: initializeCommand is invalid in:\n  %s\n' \
            "$devcontainer_file" >&2

        printf '\nExpected:\n%s\n' \
            "$expected_command" >&2

        printf '\nActual:\n%s\n' \
            "$actual_command" >&2

        printf '\nThe expected and actual initializeCommand values are not synchronized.\n' >&2
        printf 'From the project root, run the following command in a single line:\n\n' >&2
        printf 'docker compose -f compose.ai-dev-cold.yml run --rm --build --no-deps \n' >&2
        printf 'ai_dev_cold_base /workspace/ai_dev_scripts/initialize-ai-dev-with-project.sh\n\n' >&2

        return 1
    fi

    printf 'Validated initializeCommand: %s\n' \
        "$devcontainer_file"
}