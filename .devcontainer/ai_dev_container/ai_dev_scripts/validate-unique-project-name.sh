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
ERROR: UNIQUE_PROJECT_NAME must be defined in .devcontainer/ai_dev_container/.env.

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