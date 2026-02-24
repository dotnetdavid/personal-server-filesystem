# Obsidian personal-server-filesystem MCP Server

A minimal, isolated, Dockerized Model Context Protocol (MCP) filesystem server that exposes a single Obsidian vault (`/personal`) to MCP‑compatible clients such as LM Studio and JetBrains IDEs. This project serves as a clean, professional reference implementation for building vault‑scoped filesystem servers using the official `@modelcontextprotocol/server-filesystem` package.

The design emphasizes determinism, portability, and strict Obsidian vault isolation, making it suitable as a template for future multi‑vault MCP server ecosystems.

---

## Features

- Official MCP filesystem server (`@modelcontextprotocol/server-filesystem`)
- Strict Obsidian vault isolation — only the Personal vault is exposed
- Deterministic Docker build using Node 20‑slim
- docker-compose for clean lifecycle management
- Makefile‑driven automation with portable POSIX scripts
- Environment‑specific configuration isolated in `env/`
- TOML configuration for LM Studio, PyCharm, and other MCP clients
- Fully compatible with MSYS2, PowerShell, CMD, and Linux

---

## Architecture Overview

```
+-------------------------------+
|  MCP Client (LM Studio, IDE)  |
+---------------+---------------+
                |
                | MCP over stdio
                v
+-----------------------------------------------+
|  Docker Container: personal-server-filesystem  |
|-----------------------------------------------|
|  Node 20-slim                                 |
|  @modelcontextprotocol/server-filesystem      |
|                                               |
|  Vault Root: /personal                        |
+----------------------+------------------------+
                       |
                       | Bind Mount (rw)
                       v
        Z:\path-to-your-vault\Personal
```

The container runs the MCP filesystem server with `/personal` as its root. All filesystem operations are restricted to this directory.

---

## Directory Structure

```
personal-server-filesystem/
├── Dockerfile
├── docker-compose.yaml
├── Makefile
├── mcp-personal-server-filesystem.toml
├── README.md
├── env/
│   ├── env.compose
│   ├── env.compose.example
│   ├── env.mk
│   ├── env.mk.example
│   ├── env.sh
│   └── env.sh.example
└── scripts/
    ├── build.sh
    ├── clean.sh
    ├── daemon.sh
    ├── logs.sh
    ├── nuke.sh
    ├── run.sh
    ├── status.sh
    └── stop.sh
```

---

## Prerequisites

- Docker Desktop (or compatible Docker runtime)
- Make (GNU Make recommended)
- Bash (MSYS2, WSL, Linux, or macOS)
- Node is not required on the host; it is installed inside the container

---

## Build & Run

### Build the Docker image
`make build`

### Run interactively (foreground)
`make run`

### Run detached (daemon mode)
`make daemon`

### View logs
`make logs`

### Container status
`make status`

### Stop the container
`make stop`

### Clean dangling Docker artifacts
`make clean`

### Nuclear reset (full teardown + rebuild)
`make nuke`

This removes all containers, images, and dangling artifacts associated with the project, then rebuilds from scratch.

---

## Docker Compose Configuration

```yaml
services:
  personal-server-filesystem:
    build:
      context: .
    image: personal-server-filesystem:latest
    container_name: mcp-personal-server-filesystem
    command: ["/app/node_modules/.bin/mcp-server-filesystem", "/personal"]
    env_file:
      - ./env/env.compose
    volumes:
      - "${VAULT_ROOT}:/personal:rw"
    stdin_open: true
    tty: true
```

Key points:

- The Obsidian vault is mounted read/write at `/personal`; set `VAULT_ROOT` in `env/env.sh` and run `make sync-env` (or create `env/env.compose`) so `${VAULT_ROOT}` is defined for compose.
- The server binary is `mcp-server-filesystem`.
- The container name is stable for TOML integration.

---

## Dockerfile

```dockerfile
FROM node:20-slim

WORKDIR /app

RUN npm install --omit=dev @modelcontextprotocol/server-filesystem@2026.1.14

ENV PATH="/app/node_modules/.bin:${PATH}"
ENV VAULT_ROOT=/personal

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD pgrep -f "mcp-server-filesystem" || exit 1

CMD ["mcp-server-filesystem", "/personal"]
```

## MCP Client Configuration (TOML)
```
name = "personal-server-filesystem"
version = "1.0.0"
description = "Filesystem MCP server for the Personal vault."

[server]
command = [
    "docker",
    "exec",
    "-i",
    "mcp-personal-server-filesystem",
    "mcp-server-filesystem",
    "/personal"
]

[env]
VAULT_ROOT = "/personal"

Place this file in your MCP client’s configuration directory.
```

## Environment Configuration

Machine‑specific paths are isolated in `env/env.mk` (Make) and `env/env.sh` (scripts).  
This ensures:

- No hardcoded paths in Makefile or scripts
- Portability across machines
- Clean separation of logic and configuration

Example (`env/env.sh`):
```
export DOCKER="docker"
export PROJECT_ROOT="/z/path-to/personal-server-filesystem"
export VAULT_ROOT="/z/path-to-target-vault/vault"
export CONTAINER_MOUNT="$VAULT_ROOT:/personal"
```


## Security Model

- The server exposes only the mounted vault directory
- No access to the host filesystem outside `/personal`
- No network access required
- Container boundary provides additional isolation

This makes the server safe for use with personal or sensitive vaults.

### Why the vault is mounted read/write

The MCP filesystem server supports operations that modify files, including:
- creating new notes
- updating existing notes
- renaming files
- there is no delete function - use move_file to move target files to a trash folder

For this reason, the vault must be mounted read/write.  
If you only need read-only access (e.g., search, summarization), you may change the mount to `:ro`, but write operations will fail.

---
### Windows Path Handling (MSYS2, PowerShell, CMD)
This project was created using MSYS2‑style POSIX paths inside environment files and scripts:
```
/z/your-vault-path/Personal
/z/path-to-git-project/personal-server-filesystem
```


These paths are required because:
- The Makefile and scripts run under Bash
- Docker Desktop on Windows accepts both POSIX and Windows paths
- MSYS2 provides consistent behavior across shells

You may set VAULT_ROOT in env/env.sh or env/env.mk using either format:

#### POSIX (recommended for Bash):
`/your-vault-path/Personal`

#### Windows (works with Docker Desktop):
`Z:\your-vault-path\Personal`

#### Important Notes
- env/env.sh is sourced by Bash scripts → POSIX paths recommended
- env/env.mk is used by Make → POSIX paths recommended
- docker-compose.yaml receives the value unchanged → both formats work


---
## Attribution

This project wraps and depends on the official Model Context Protocol filesystem server:

- `@modelcontextprotocol/server-filesystem`  
  https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem

- MCP Servers (reference implementation)  
  https://github.com/modelcontextprotocol/servers

The upstream MCP servers project is licensed under the Apache License 2.0.  
This project includes attribution in accordance with that license.

---

## License

Licensed under the **Apache License, Version 2.0**.

You may obtain a copy of the license at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under this license is distributed on an **AS IS** BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

See the `LICENSE` file for the full text.

---

## Roadmap

- Publish Docker image to Docker Hub (`personal-server-filesystem`)
- Add automated MCP test suite
- Provide boilerplate templates for:
  - Work vault
  - Research vault
  - Multi‑vault orchestration
- Add CI workflows for build + lint + integration tests
- Expand documentation for MCP newcomers

---

## Acknowledgments

Built using the official Model Context Protocol filesystem server:  
`@modelcontextprotocol/server-filesystem`

This project is part of a broader effort to create deterministic, reproducible, vault‑scoped MCP servers for personal knowledge systems.

<ribbit>