#!/usr/bin/env bash

build_devcontainer_initialize_command() {
    local -r project_primary_service="$1"

    if [[ -z "${project_primary_service:-}" ]]; then
        fail "project_primary_service has not been initialized."
    fi

    if [[ ! "$project_primary_service" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
        fail \
            "PROJECT_PRIMARY_SERVICE contains invalid characters: ${project_primary_service}"
    fi

    printf '%s' \
        'docker compose -f ${localWorkspaceFolder}/compose.ai-dev-cold.yml run --rm --build --no-deps ai_dev_cold_base /workspace/ai_dev_scripts/run-validate-with-project.sh && docker compose -f ${localWorkspaceFolder}/compose.ai-dev-with-project.yml build '"${project_primary_service}"
}