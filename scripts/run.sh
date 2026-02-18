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

"$DOCKER" compose up