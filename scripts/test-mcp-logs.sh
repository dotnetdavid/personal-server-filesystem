#!/usr/bin/bash
set -euo pipefail

LOG_PATTERN="[mcp-test] Client connected"

if docker logs mcp-test 2>&1 | grep -F "$LOG_PATTERN" >/dev/null; then
    echo "Passed"
    exit 0
else
    echo "Failed: expected log entry '$LOG_PATTERN' not found"
    echo "Recent logs:"
    docker logs mcp-test | tail -n 20
    exit 1
fi