prepare_project_bridge() {

    if ! declare -p bridge_file >/dev/null 2>&1; then 
        fail "validated_files has not been initialized." 
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
    local escaped_path

    bridge_content=$'# This file must exist before DevContainers initialization.\ninclude:\n  - path:'

    for compose_file in "${validated_files[@]}"; do
        # YAML represents a single quote inside a single-quoted scalar
        # by doubling it.
        escaped_path="${compose_file//\'/\'\'}"

        bridge_content+=$'\n'"      - './${escaped_path}'"
    done

    # Preserve the existing file, but clear its current contents.
    : > "$bridge_file"

    # Append the completely prepared replacement content.
    printf '%s\n' "$bridge_content" >> "$bridge_file"

    printf 'Updated bridge: %s\n' "$bridge_file"
    printf 'Primary service: %s\n' "$project_primary_service"
}