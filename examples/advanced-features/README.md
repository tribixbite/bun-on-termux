# Advanced Features Example

This example demonstrates advanced Bun capabilities on Termux Android.

## Features Demonstrated

- **HTTP Server** (`server.ts`) - Full-featured web server with API endpoints
- **Performance Benchmarks** (`benchmark.ts`) - CPU, memory, and I/O performance testing
- **SQLite Database** (`sqlite-demo.ts`) - Database operations with transactions
- **Cryptography** (`crypto-demo.ts`) - Hashing, encryption, and Web Crypto API
- **HTTP Client** (`fetch-demo.ts`) - Fetch API, concurrent requests, file downloads

## Running the Examples

```bash
# Install dependencies
bun install

# Start the web server
bun dev
# or: bun server.ts

# Run performance benchmarks
bun run benchmark

# Test SQLite functionality
bun run sqlite

# Demonstrate cryptography features
bun run crypto

# Test HTTP client capabilities
bun run fetch

# Build optimized version
bun run build

# Run tests
bun test
```

## Server Features

The HTTP server (`bun dev`) provides:

- **Web Interface**: Visit `http://localhost:3000` for interactive demo
- **API Endpoints**:
  - `/api/system` - System information and Bun version
  - `/api/files` - File system operations demo
  - `/api/benchmark` - Real-time performance test

## Performance Notes

These examples are designed to work well on Android hardware:

- Benchmarks are scaled appropriately for mobile CPUs
- File operations use `/tmp` for temporary data
- Memory usage is monitored and reported
- Error handling accounts for Termux limitations

## Termux-Specific Considerations

- SQLite uses in-memory database (no storage permissions needed)
- Network requests may require stable connection
- File operations respect Android filesystem limitations
- Cryptography uses standard Web APIs for maximum compatibility