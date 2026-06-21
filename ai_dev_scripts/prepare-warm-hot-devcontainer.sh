#!/usr/bin/env bash

prepare_warm_hot_devcontainer() {
    local devcontainer_file="$1"

    if [[ ! -f "$devcontainer_file" ]]; then
        fail "Dev Container configuration does not exist: ${devcontainer_file}"
    fi

    local initialize_command

    initialize_command="$(build_devcontainer_initialize_command)"

    local updated_json

    if ! updated_json="$(
        jq \
            --arg initialize_command "$initialize_command" \
            '.initializeCommand = $initialize_command' \
            "$devcontainer_file"
    )"; then
        fail \
            "Could not update initializeCommand in: ${devcontainer_file}"
    fi

    # Preserve the existing file itself, but replace all of its contents.
    : > "$devcontainer_file"
    printf '%s\n' "$updated_json" >> "$devcontainer_file"

    printf 'Updated initializeCommand: %s\n' "$devcontainer_file"
}