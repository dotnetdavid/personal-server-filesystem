# Makefile — personal-server-filesystem
#
# Goals:
# - Be safe by default (no surprise failures or destructive ops without intent)
# - Be maintainable (single source of truth for names/commands)
# - Be consistent (normal + test targets use the same env/docker configuration)

# ------------------------------------------------------------------------------
# Optional machine-specific configuration
#   - env/env.mk is intentionally ignored by git (local dev/CI machine config)
#   - Use "-include" so a fresh clone doesn't hard-fail on "make help".
# ------------------------------------------------------------------------------
-include env/env.mk

.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Project constants
# ------------------------------------------------------------------------------
PROJECT_NAME          := personal-server-filesystem
TEST_NETWORK          := mcp-test-network
TEST_CONTAINER        := mcp-test
TEST_HARNESS_NAME     := mcp-personal-server-filesystem-test-harness
TEST_IMAGE_BASE       := $(PROJECT_NAME):base
TEST_IMAGE_TEST       := $(PROJECT_NAME):test
TEST_IMAGE_HARNESS    := $(PROJECT_NAME):test-harness

ENV_SH                := env/env.sh
ENV_COMPOSE           := env/env.compose

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

# Run a command in a bash shell that sources env/env.sh first.
# This aligns with your existing scripts (they already depend on bash).
define with_env
bash -euo pipefail -c ' \
  if [[ ! -f "$(ENV_SH)" ]]; then \
    echo "ERROR: $(ENV_SH) not found. Copy $(ENV_SH).example and configure paths."; \
    exit 1; \
  fi; \
  source "$(ENV_SH)"; \
  $(1) \
'
endef

.PHONY: help \
        build run daemon stop logs status \
        clean clean-force nuke nuke-force \
        init check-env env-compose \
        build-base build-test build-harness \
        test-network test-infra test-logs \
        test-standup test-clean test-teardown test-reset \
        promote

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
help:
	@echo ""
	@echo "$(PROJECT_NAME) — Make Targets"
	@echo ""
	@echo "Core:"
	@echo "  make build          Build the Docker image"
	@echo "  make run            Run the container (foreground)"
	@echo "  make daemon         Run the container detached"
	@echo "  make stop           Stop running containers"
	@echo "  make logs           Tail container logs"
	@echo "  make status         Show container and image status"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean          Remove dangling Docker artifacts (prompted)"
	@echo "  make clean-force    Clean without prompt"
	@echo "  make nuke           Full teardown and rebuild (prompted)"
	@echo "  make nuke-force     Nuke without prompt"
	@echo ""
	@echo "Env:"
	@echo "  make init           Validate env and generate $(ENV_COMPOSE)"
	@echo "  make env-compose    Regenerate $(ENV_COMPOSE) from $(ENV_SH)"
	@echo ""
	@echo "Testing:"
	@echo "  make test-network   Create the docker network for tests"
	@echo "  make build-base     Build base test image"
	@echo "  make build-test     Build test image and start the test container"
	@echo "  make build-harness  Build test-harness image"
	@echo "  make test-infra     Run infra tests inside the harness container"
	@echo "  make test-logs      Host-side log checks"
	@echo "  make test-standup   Stand up full test scaffolding"
	@echo "  make test-teardown  Tear down test scaffolding"
	@echo "  make test-reset     Teardown + standup"
	@echo ""
	@echo "Promote Test to Production:"
	@echo "  make promote	     Promote the test container to production"
	@echo ""

# ------------------------------------------------------------------------------
# Environment / init
# ------------------------------------------------------------------------------
check-env:
	@$(call with_env, \
	  :; \
	  command -v "$$DOCKER" >/dev/null 2>&1 || { echo "ERROR: Docker not found at: $$DOCKER"; exit 1; }; \
	  [[ -n "$${PROJECT_ROOT:-}" ]] || { echo "ERROR: PROJECT_ROOT is not set in $(ENV_SH)"; exit 1; }; \
	  [[ -n "$${VAULT_ROOT:-}" ]] || { echo "ERROR: VAULT_ROOT is not set in $(ENV_SH)"; exit 1; } \
	)

# Generate env/env.compose for docker compose usage.
# We intentionally *source* env/env.sh (rather than awk-parsing shell) so quoting/whitespace works.
env-compose:
	@$(call with_env, \
	  umask 077; \
	  echo "Generating $(ENV_COMPOSE) from $(ENV_SH)..."; \
	  printf "VAULT_ROOT=%s\n" "$$VAULT_ROOT" > "$(ENV_COMPOSE)"; \
	  echo "$(ENV_COMPOSE) updated." \
	)

# init is kept as a lightweight, reliable prerequisite for most dev targets.
# It validates env and updates env/env.compose, but avoids chmod'ing scripts broadly.
init: check-env env-compose
	@true

# ------------------------------------------------------------------------------
# Core workflow (delegates to scripts for single-source-of-truth behavior)
# ------------------------------------------------------------------------------
build: init
	@./scripts/build.sh

run: init
	@./scripts/run.sh

daemon: init
	@./scripts/daemon.sh

stop:
	@./scripts/stop.sh

logs:
	@./scripts/logs.sh

status:
	@./scripts/status.sh

clean:
	@./scripts/clean.sh

clean-force:
	@CONFIRM=1 ./scripts/clean.sh

nuke: init
	@./scripts/nuke.sh

nuke-force: init
	@CONFIRM=1 ./scripts/nuke.sh

# ------------------------------------------------------------------------------
# Testing workflow (uses env/env.sh for DOCKER + VAULT_ROOT consistency)
# ------------------------------------------------------------------------------
test-network: init
	@$(call with_env, \
	  "$$DOCKER" network inspect "$(TEST_NETWORK)" >/dev/null 2>&1 || "$$DOCKER" network create "$(TEST_NETWORK)"; \
	  echo "$(TEST_NETWORK) ready" \
	)

build-base: init
	@$(call with_env, \
	  "$$DOCKER" build --no-cache -t "$(TEST_IMAGE_BASE)" -f Dockerfile . \
	)

build-test: init test-network build-base
	@$(call with_env, \
	  "$$DOCKER" build --no-cache -t "$(TEST_IMAGE_TEST)" -f Dockerfile.test .; \
	  "$$DOCKER" rm -f "$(TEST_CONTAINER)" >/dev/null 2>&1 || true; \
	  "$$DOCKER" run -d \
	    --network "$(TEST_NETWORK)" \
	    --name "$(TEST_CONTAINER)" \
	    -v "$$VAULT_ROOT:/personal" \
	    "$(TEST_IMAGE_TEST)" \
	)

build-harness: init
	@$(call with_env, \
	  "$$DOCKER" build --no-cache -t "$(TEST_IMAGE_HARNESS)" -f Dockerfile.test-harness . \
	)

test-infra: init test-network build-harness
	@$(call with_env, \
	  "$$DOCKER" run --rm \
	    --network "$(TEST_NETWORK)" \
	    --name "$(TEST_HARNESS_NAME)" \
	    --entrypoint "" \
	    "$(TEST_IMAGE_HARNESS)" \
	    /app/run-infra-tests.sh \
	)

test-logs:
	@./scripts/test-mcp-logs.sh

test-standup: test-network build-base build-test build-harness
	@echo "Test standup complete."

test-clean: init
	@$(call with_env, \
	  echo "Cleaning exited containers..."; \
	  ids=$$("$${DOCKER}" ps -aq -f status=exited 2>/dev/null || true); \
	  if [[ -n "$$ids" ]]; then "$$DOCKER" rm $$ids >/dev/null 2>&1 || true; fi; \
	  echo "Pruning dangling images..."; \
	  "$$DOCKER" image prune -f >/dev/null || true; \
	  echo "Pruning unused networks..."; \
	  "$$DOCKER" network prune -f >/dev/null || true; \
	  echo "Docker test environment cleaned." \
	)

test-teardown: init
	@$(call with_env, \
	  echo "Stopping and removing test harness container..."; \
	  "$$DOCKER" rm -f "$(TEST_HARNESS_NAME)" >/dev/null 2>&1 || true; \
	  echo "Stopping and removing test container..."; \
	  "$$DOCKER" rm -f "$(TEST_CONTAINER)" >/dev/null 2>&1 || true; \
	  echo "Removing test network..."; \
	  "$$DOCKER" network rm "$(TEST_NETWORK)" >/dev/null 2>&1 || true; \
	  echo "Pruning dangling images..."; \
	  "$$DOCKER" image prune -f >/dev/null || true; \
	  echo "Test environment torn down." \
	)

test-reset: test-teardown test-standup
	@echo "Test environment reset and ready."

promote: init
	@$(call with_env, \
	  echo "Tagging test image as production..."; \
	  "$$DOCKER" tag "$(TEST_IMAGE_TEST)" "$(PROJECT_NAME):prod"; \
	  echo "Pushing production image..."; \
	  "$$DOCKER" push "$(PROJECT_NAME):prod"; \
	  echo "Promotion complete."; \
	)