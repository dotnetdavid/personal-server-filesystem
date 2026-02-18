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
    echo "WARNING: This will remove dangling Docker artifacts (images, containers, volumes, networks)."
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Cleaning Docker artifacts for personal-vault-filesystem..."

# Remove dangling containers (exited, unnamed)
"$DOCKER" container prune -f

# Remove dangling volumes (unused)
"$DOCKER" volume prune -f

# Remove dangling networks (unused)
"$DOCKER" network prune -f

# Remove project image(s) if present
IMAGES=$("$DOCKER" images -q "personal-vault-filesystem*" 2>/dev/null)
if [[ -n "$IMAGES" ]]; then
    echo "$IMAGES" | xargs "$DOCKER" rmi -f 2>/dev/null || true
fi

# Remove dangling images (unused) — only removes images not referenced by any container
"$DOCKER" image prune -f

echo "Cleanup complete."