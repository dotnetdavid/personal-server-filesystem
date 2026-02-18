# Makefile — personal-vault-filesystem

# Load machine-specific configuration
include env/env.mk

# Default target
.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "personal-vault-filesystem — Make Targets"
	@echo ""
	@echo "  make build      Build the Docker image"
	@echo "  make run        Run the container (foreground)"
	@echo "  make daemon     Run the container detached"
	@echo "  make stop       Stop running containers"
	@echo "  make logs       Tail container logs"
	@echo "  make status     Show container and image status"
	@echo "  make clean      Remove dangling Docker artifacts"
	@echo "  make nuke       Full teardown and rebuild"
	@echo "  make sync-env   Sync path variables for docker-compose"
	@echo "  make help       Show this help menu"
	@echo ""

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build: sync-env
	@./scripts/build.sh

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
run: sync-env
	@./scripts/run.sh

# ---------------------------------------------------------------------------
# Stop
# ---------------------------------------------------------------------------
stop:
	@./scripts/stop.sh

# ---------------------------------------------------------------------------
# Logs
# ---------------------------------------------------------------------------
logs:
	@./scripts/logs.sh

# ---------------------------------------------------------------------------
# Status
# ---------------------------------------------------------------------------
status:
	@./scripts/status.sh

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
clean:
	@./scripts/clean.sh

# ---------------------------------------------------------------------------
# Nuke - Rebuild from scorched earth
# ---------------------------------------------------------------------------
nuke: sync-env
	@./scripts/nuke.sh

# ---------------------------------------------------------------------------
# daemon
# ---------------------------------------------------------------------------
daemon: sync-env
	@./scripts/daemon.sh

# ---------------------------------------------------------------------------
# sync-env
# ---------------------------------------------------------------------------
.PHONY: sync-env
sync-env:
	@echo "Generating env/env.compose from env/env.sh..."
	@awk '/^export VAULT_ROOT=/{gsub("export ", "", $$0); print $$0}' env/env.sh > env/env.compose
	@echo "env/env.compose updated."