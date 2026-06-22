get_env_value() {
    local key="$1"

    awk -v key="$key" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            value = $0
            sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "", value)
        }

        END {
            print value
        }
    ' "$env_file"
}

strip_outer_quotes() {
    local value="$1"

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
        value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
        value="${value:1:${#value}-2}"
    fi

    printf '%s' "$value"
}

trim() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

get_clean_env_value() {
    local key="$1"
    local value

    value="$(get_env_value "$key")"
    value="$(trim "$value")"
    value="$(strip_outer_quotes "$value")"
    value="$(trim "$value")"

    printf '%s' "$value"
}

validate_with_project_envs() {
    if [[ ! -f "$env_file" ]]; then
        fail "Required project .env file was not found: ${env_file}"
    fi

    project_compose_files="$(
        get_clean_env_value PROJECT_COMPOSE_FILES
    )"

    project_primary_service="$(
        get_clean_env_value PROJECT_PRIMARY_SERVICE
    )"

    git_path="$(
        get_clean_env_value GIT_PATH
    )"

    if [[ -z "$project_compose_files" ]]; then
        cat >&2 <<'EOF'
ERROR: PROJECT_COMPOSE_FILES must be defined in the project-root .env.

Example:

PROJECT_COMPOSE_FILES=compose.primary.yml,compose.override.yml

Separate paths with commas.
Spaces inside paths are supported.
Commas inside filenames are not supported.
EOF
        exit 1
    fi

    if [[ -z "$project_primary_service" ]]; then
        cat >&2 <<'EOF'
ERROR: PROJECT_PRIMARY_SERVICE must be defined in the project-root .env.

Example:

PROJECT_PRIMARY_SERVICE=app
EOF
        exit 1
    fi

    case "$git_path" in
        ./.git | ./.fake_git)
            ;;
        *)
        cat >&2 <<'EOF'
ERROR: GIT_PATH must be defined in the project-root .env and must have one of these values:

GIT_PATH=./.git
GIT_PATH=./.fake_git

Use ./.fake_git if the project does not use Git.
EOF
            exit 1
            ;;
    esac

    IFS=',' read -r -a compose_files <<< "$project_compose_files"

    validated_files=()

    local compose_file

    for compose_file in "${compose_files[@]}"; do
        compose_file="$(trim "$compose_file")"

        if [[ -z "$compose_file" ]]; then
            continue
        fi

        # Keep paths project-relative and prevent "././compose.yml".
        compose_file="${compose_file#./}"

        if [[ ! -f "${project_root}/${compose_file}" ]]; then
            fail "Project Compose file does not exist: ${compose_file}"
        fi

        validated_files+=("$compose_file")
    done

    if [[ "${#validated_files[@]}" -eq 0 ]]; then
        fail \
            "PROJECT_COMPOSE_FILES did not contain any usable file paths."
    fi

    printf 'Validated %d project Compose file(s).\n' \
        "${#validated_files[@]}"

    printf 'Validated primary service: %s\n' \
        "$project_primary_service"
}