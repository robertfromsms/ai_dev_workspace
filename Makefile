AI_DEV_COMPOSE := .devcontainer/ai_dev_container/compose.ai-dev.yml

.PHONY: ai-dev-validate
ai-dev-validate:
	docker compose -f $(AI_DEV_COMPOSE) run --rm --build --no-deps \
		ai_dev_user \
		/workspace/.devcontainer/ai_dev_container/ai_dev_scripts/run-validate-unique-project-name.sh

.PHONY: ai-dev-up
ai-dev-up: ai-dev-validate
	docker compose -f $(AI_DEV_COMPOSE) up -d

.PHONY: agent-shell
agent-shell:
	docker compose -f $(AI_DEV_COMPOSE) exec ai_dev_agent bash

.PHONY: codex
codex:
	docker compose -f $(AI_DEV_COMPOSE) exec ai_dev_agent \
		bash -lc 'exec codex'

.PHONY: opencode
opencode:
	docker compose -f $(AI_DEV_COMPOSE) exec ai_dev_agent \
		bash -lc 'exec opencode'