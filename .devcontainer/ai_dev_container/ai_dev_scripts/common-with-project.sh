script_dir="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

get_value_from_manifest() {
    local -r dot_key="$1"
    local -r manifest_file="$2"
    jq --exit-status --raw-output "$dot_key" "$manifest_file"
}

source "${script_dir}/validate-unique-project-name.sh"