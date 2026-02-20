# Makefile — personal-server-filesystem

# Load machine-specific configuration
include env/env.mk

# Default target
.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "personal-server-filesystem — Make Targets"
	@echo ""
	@echo "  make build      Build the Docker image"
	@echo "  make run        Run the container (foreground)"
	@echo "  make daemon     Run the container detached"
	@echo "  make stop       Stop running containers"
	@echo "  make logs       Tail container logs"
	@echo "  make status     Show container and image status"
	@echo "  make clean      Remove dangling Docker artifacts"
	@echo "  make nuke       Full teardown and rebuild"
	@echo "  make init       initialize the project"
	@echo "  make help       Show this help menu"
	@echo ""

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build: init
	@./scripts/build.sh

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
run: init
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
nuke: init
	@./scripts/nuke.sh

# ---------------------------------------------------------------------------
# daemon
# ---------------------------------------------------------------------------
daemon: init
	@./scripts/daemon.sh

# ---------------------------------------------------------------------------
# init
# ---------------------------------------------------------------------------
.PHONY: init
init:
	@echo "Generating env/env.compose from env/env.sh..."
	@awk '/^export VAULT_ROOT=/{gsub("export ", "", $$0); print $$0}' env/env.sh > env/env.compose
	@chmod +x scripts/*
	@echo "env/env.compose updated."