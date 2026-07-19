prepare_project_bridge() {
    local -r bridge_file="$1"
    local -r validated_files_variable_name="$2"
    local -r project_local_dev_service="$3"

    if ! declare -p bridge_file >/dev/null 2>&1; then
        fail "bridge_file has not been initialized."
    fi

    if [[ ! -f "$bridge_file" ]]; then
        fail "Project bridge file does not exist: ${bridge_file}"
    fi

    local declaration

    if ! declaration="$(
        declare -p "$validated_files_variable_name" 2>/dev/null
    )"; then
        fail "$validated_files_variable_name has not been declared."
    fi

    if [[ ! "$declaration" =~ ^declare\ -[^[:space:]]*a ]]; then
        fail "$validated_files_variable_name is not an indexed Bash array."
    fi

    local -n validated_files="$validated_files_variable_name"

    if [[ "${#validated_files[@]}" -eq 0 ]]; then
        fail "validated_files does not contain any Compose file paths."
    fi

    local bridge_content
    local compose_file
    local bridge_include_paths_json
    local -a bridge_include_paths=()

    for compose_file in "${validated_files[@]}"; do
        bridge_include_paths+=("./${compose_file}")
    done

    if ! bridge_include_paths_json="$(
        jq \
            --compact-output \
            --null-input \
            --args \
            '$ARGS.positional' \
            "${bridge_include_paths[@]}"
    )"; then
        fail "Could not encode project Compose file paths."
    fi

    if ! bridge_content="$(
        printf '%s\n' "$bridge_include_paths_json" |
            yq \
                --input-format json \
                --output-format yaml \
                --prettyPrint \
                --security-disable-file-ops \
                '{"include": [{"path": .}]}'
    )"; then
        fail "Could not generate project bridge YAML."
    fi

    printf '%s\n%s\n' \
        '# This file must exist before DevContainers initialization.' \
        "$bridge_content" > "$bridge_file"

    printf 'Updated bridge: %s\n' "$bridge_file"
    printf 'Local Development service: %s\n' "$project_local_dev_service"
}