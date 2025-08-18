# Examples

This directory contains example projects and configurations for Bun on Termux.

## basic-project

A simple TypeScript project demonstrating:
- Package.json script execution
- TypeScript compilation and execution  
- Bun API usage
- Package dependency management
- Local bunfig.toml configuration

### Usage

```bash
cd examples/basic-project
bun install
bun run dev
```

### What it demonstrates

1. **TypeScript Support**: Direct `.ts` file execution
2. **Package Management**: Installing and using npm packages
3. **Bun APIs**: Using Bun.version, Bun.file, performance APIs
4. **Script Running**: `bun run` command with package.json scripts
5. **Build System**: `bun build` for bundling
6. **Configuration**: Project-specific bunfig.toml settings

### Expected Output

```
🥟 Hello from Bun on Termux!
✅ TypeScript support working
⚡ Fast JavaScript runtime
📦 Bun version: 1.2.20
🏠 Platform: linux-arm64
📋 Project: bun-termux-example v1.0.0
⏱️  Timing precision: 10.XX ms
```

## Configuration Examples

### Global Configuration (`~/.bun/bunfig.toml`)
- See `../config/bunfig-global.toml`
- Used for global settings (when applicable)
- **Note**: Global installs don't read this file

### Project Configuration (`./bunfig.toml`)
- See `basic-project/bunfig.toml`  
- Used for local project operations
- Overrides global settings in this directory

## Common Issues

### Package Installation
If you encounter permission errors:
```bash
# The wrapper should handle this automatically, but you can be explicit:
bun install --backend=copyfile
```

### Global Packages
For global packages, the backend is automatically set:
```bash
# This now works automatically:
bun i -g some-package
```

### Script Execution
Package.json scripts are handled by the wrapper:
```bash
# Both of these work:
bun run dev
bun run build
```