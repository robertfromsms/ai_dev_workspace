get_env_value() {
    local -r key="$1"
    local -r env_file="$2"

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
    local -r key="$1"
    local -r env_file="$2"
    local value

    value="$(get_env_value "$key" "$env_file")"
    value="$(trim "$value")"
    value="$(strip_outer_quotes "$value")"
    value="$(trim "$value")"

    printf '%s' "$value"
}

# this is used for both with-project and with the cold environment
validate_unique_project_name() {
    local -r env_file="$1"

    if [[ ! -f "$env_file" ]]; then
        fail "Required project .env file was not found: ${env_file}"
    fi

    local -r unique_project_name="$(
        get_clean_env_value UNIQUE_PROJECT_NAME "$env_file"
    )"

    if [[ -z "$unique_project_name" ]]; then
        cat >&2 <<'EOF'
ERROR: UNIQUE_PROJECT_NAME must be defined in the project-root .env.

Example:

UNIQUE_PROJECT_NAME=stars_sweeper
EOF
        exit 1
    fi

    if [[ ! "$unique_project_name" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
        cat >&2 <<'EOF'
ERROR: UNIQUE_PROJECT_NAME has an invalid Docker Compose project name format.

Found:

UNIQUE_PROJECT_NAME=${unique_project_name}

Docker Compose project names must:
- use only lowercase letters, digits, dashes, and underscores
- start with a lowercase letter or digit

Examples:

UNIQUE_PROJECT_NAME=stars_sweeper
UNIQUE_PROJECT_NAME=stars-sweeper
UNIQUE_PROJECT_NAME=stars123
EOF
        exit 1
    fi

    printf 'Validated project name: %s\n' \
        "$unique_project_name"
}

validate_with_project_envs() {
    local -r env_file="$1"
    local -r project_root="$2"
    local -n validated_files="$3"
    local -n project_primary_service="$4"

    # reset validated_files
    validated_files=()

    if [[ ! -f "$env_file" ]]; then
        fail "Required project .env file was not found: ${env_file}"
    fi

    local -r project_compose_files="$(
        get_clean_env_value PROJECT_COMPOSE_FILES "$env_file"
    )"

    project_primary_service="$(
        get_clean_env_value PROJECT_PRIMARY_SERVICE "$env_file"
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

    local -a compose_files=()

    IFS=',' read -r -a compose_files <<< "$project_compose_files"

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