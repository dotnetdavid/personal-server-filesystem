#!/usr/bin/bash
set -euo pipefail

# Validate env file exists
ENV_FILE="$(dirname "$0")/../env/env.sh"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: env/env.sh not found. Copy env/env.sh.example and configure paths."
    exit 1
fi

# Load environment
# shellcheck disable=SC1090
source "$ENV_FILE"

# Validate Docker binary
if ! command -v "$DOCKER" &> /dev/null; then
    echo "ERROR: Docker not found at: $DOCKER"
    exit 1
fi

"$DOCKER" build -t personal-server-filesystem "$PROJECT_ROOT"
