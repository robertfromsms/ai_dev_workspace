prepare_project_bridge() {

    if ! declare -p bridge_file >/dev/null 2>&1; then
        fail "bridge_file has not been initialized."
    fi

    if [[ ! -f "$bridge_file" ]]; then
        fail "Project bridge file does not exist: ${bridge_file}"
    fi

    if ! declare -p validated_files >/dev/null 2>&1; then
        fail "validated_files has not been initialized."
    fi

    if [[ "$(declare -p validated_files)" != "declare -a"* ]]; then
        fail "validated_files exists, but it is not an indexed Bash array."
    fi

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
    printf 'Primary service: %s\n' "$project_primary_service"
}