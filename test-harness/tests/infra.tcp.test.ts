import { describe, it, expect } from 'vitest';
import net from 'net';

describe('Network Infrastructure: TCP', () => {
  it('should connect to mcp-test on port 3000', async () => {
    const host = 'mcp-test';
    const port = 3000;

    await new Promise<void>((resolve, reject) => {
      const socket = net.connect(port, host, () => {
        // Connected successfully
        socket.end();
        resolve();
      });
      socket.on('error', (err) => {
        reject(err);
      });
    });

    expect(true).toBe(true); // If we reach here, connection succeeded
  });
});