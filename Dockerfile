# Dockerfile — personal-server-filesystem

FROM node:22-slim

WORKDIR /app

# Install procps so HEALTHCHECK can use pgrep (node:20-slim does not include it)
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends procps \
  && rm -rf /var/lib/apt/lists/*

# Install the official MCP filesystem server (pinned version for reproducibility)
RUN npm install --omit=dev @modelcontextprotocol/server-filesystem@2026.1.14

# Ensure local node_modules/.bin is on PATH
ENV PATH="/app/node_modules/.bin:${PATH}"


# Healthcheck to ensure the MCP server is running
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD pgrep -f "mcp-server-filesystem" || exit 1

# Run the filesystem MCP server scoped to this vault root
CMD ["mcp-server-filesystem", "/personal"]