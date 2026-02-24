import { describe, it, expect } from 'vitest';
import dns from 'dns/promises';

describe('Network Infrastructure: DNS', () => {
  it('should resolve the test container hostname (mcp-test)', async () => {
    // Try to resolve the hostname "mcp-test" (the test container)
    const addresses = await dns.lookup('mcp-test');
    // We expect at least one address (IPv4 or IPv6)
    expect(addresses.address).toBeDefined();
    // Optionally, print the address for debugging
    console.log('mcp-test resolved to:', addresses.address);
  });
});