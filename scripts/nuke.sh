#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$(dirname "$0")/../env/env.sh"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: env/env.sh not found. Copy env/env.sh.example and configure paths."
    exit 1
fi

source "$ENV_FILE"

if ! command -v "$DOCKER" &> /dev/null; then
    echo "ERROR: Docker not found at: $DOCKER"
    exit 1
fi

# Check for confirmation
if [[ "${CONFIRM:-}" != "1" ]]; then
    echo "========================================"
    echo "WARNING: DESTRUCTIVE OPERATION"
    echo "========================================"
    echo "This will:"
    echo "  - Stop all running containers"
    echo "  - Remove all project containers"
    echo "  - Remove all project images"
    echo "  - Prune Docker system"
    echo "  - Rebuild from scratch"
    echo ""
    read -p "Are you ABSOLUTELY sure? Type 'yes' to continue: " -r
    echo
    if [[ "$REPLY" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "=== NUCLEAR RESET: personal-vault-filesystem ==="

echo "Stopping project containers..."
"$DOCKER" compose down 2>/dev/null || true
CONTAINERS=$("$DOCKER" ps -q --filter "ancestor=personal-vault-filesystem" 2>/dev/null)
if [[ -n "$CONTAINERS" ]]; then
    echo "$CONTAINERS" | xargs "$DOCKER" stop 2>/dev/null || true
fi

echo "Pruning Docker system..."
"$DOCKER" system prune -f

echo "Rebuilding image..."
"$DOCKER" build -t personal-vault-filesystem "$PROJECT_ROOT" --no-cache

echo "=== NUCLEAR RESET COMPLETE ==="