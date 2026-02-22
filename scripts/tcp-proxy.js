import net from "net";
import { spawn } from "child_process";

const PORT = 3000;

// Start the MCP filesystem server in stdio mode
const server = spawn("mcp-server-filesystem", ["/personal"], {
  stdio: ["pipe", "pipe", "inherit"]
});

// Create a TCP server that proxies to the MCP server\'s stdio
const tcpServer = net.createServer(socket => {
  console.log("[mcp-test] Client connected");

  // TCP → MCP stdin
  socket.pipe(server.stdin);

  // MCP stdout → TCP
  server.stdout.pipe(socket);

  socket.on("close", () => {
    console.log("[mcp-test] Client disconnected");
  });
});

tcpServer.listen(PORT, () => {
  console.log(`[mcp-test] TCP proxy listening on port ${PORT}`);
});