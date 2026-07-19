#!/usr/bin/env bash

build_devcontainer_initialize_command() {
    local -r project_local_dev_service="$1"

    if [[ -z "${project_local_dev_service:-}" ]]; then
        fail "project_local_dev_service has not been initialized."
    fi

    if [[ ! "$project_local_dev_service" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
        fail \
            "PROJECT_LOCAL_DEV_SERVICE contains invalid characters: ${project_local_dev_service}"
    fi

    local docker_compose_run_validate_unique_project_name='docker compose -f ${localWorkspaceFolder}/compose.ai-dev-cold.yml run --rm --build --no-deps ai_dev_cold_base /workspace/ai_dev_scripts/run-validate-unique-project-name.sh'
    local docker_compose_run_validate_with_project='docker compose -f ${localWorkspaceFolder}/compose.ai-dev-cold.yml run --rm --build --no-deps ai_dev_cold_base /workspace/ai_dev_scripts/run-validate-with-project.sh'
    local docker_compose_build_project_local_dev_service_image='docker compose -f ${localWorkspaceFolder}/compose.ai-dev-with-project.yml build '"${project_local_dev_service}"

    printf '%s && %s && %s' \
    "$docker_compose_run_validate_unique_project_name" \
    "$docker_compose_run_validate_with_project" \
    "$docker_compose_build_project_local_dev_service_image"
}