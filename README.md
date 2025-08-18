# Bun on Termux

Native Bun JavaScript runtime working on Termux Android using glibc-runner.

## Overview

This project provides working Bun binaries and wrappers for Termux Android, enabling native JavaScript/TypeScript execution without proot dependencies. Uses glibc-runner for compatibility with standard Bun binaries.

## Features

- ✅ Native Bun execution (`bun script.js`)
- ✅ Package management (`bun install`, `bun add`, `bun remove`)
- ✅ TypeScript support (`bun script.ts`)
- ✅ Build system (`bun build`)
- ⚠️ Limited `bun run` (package.json scripts) - wrapper handles this
- ❌ Environment variables don't pass through grun (known limitation)

## Installation

### Prerequisites

```bash
# Install required packages
pkg install git nodejs-lts
npm install -g bun # Install wrapper/install script

# Install glibc-runner
bash <(curl -s https://raw.githubusercontent.com/termux-pacman/glibc-packages/upds/install-glibc-runner.sh)
```

### Quick Install

```bash
# Clone this repository
git clone https://github.com/yourusername/bun-on-termux.git
cd bun-on-termux

# Run setup script
chmod +x setup.sh
./setup.sh
```

## Files

- `wrappers/bun` - Main Bun wrapper script  
- `wrappers/bun-minimal` - Minimal wrapper focusing on core issues
- `config/bunfig.toml` - Global Bun configuration for Termux
- `binaries/` - Working Bun binaries (`buno`, etc.)
- `test-bun-comprehensive.sh` - Complete test suite for all Bun commands
- `docs/` - Documentation and troubleshooting guides

## Architecture

### Core Components

1. **glibc-runner (grun)**: Compatibility layer for glibc binaries on Android
2. **Bun binary**: Native ARM64 musl binary (`buno`) 
3. **Wrapper script**: Handles Termux-specific issues like directory reading
4. **bunfig.toml**: Global configuration with `backend=copyfile` for Termux

### Known Issues

- **Environment Variables**: grun doesn't pass environment variables to child processes
- **Directory Reading**: `configureEnvForRun()` fails on Android, requiring wrapper for `bun run`
- **Build Compilation**: `bun build --compile` may have limitations on ARM64 Android

## Testing

Run the comprehensive test suite:

```bash
./test-bun-comprehensive.sh
```

Tests all Bun commands including:
- File execution (JS/TS)
- Package management 
- Build system
- Development features
- Environment handling

## Troubleshooting

### "CouldntReadCurrentDirectory" Error
This is the core issue with `bun run`. The wrapper handles this by parsing package.json directly.

### Environment Variables Not Working
Known limitation of glibc-runner. Use config files or hardcode values instead.

### Segmentation Faults
Ensure you're using the working `buno` binary, not `bun.orig`.

## Technical Details

### glibc-runner Version
- Uses glibc v2.0-3 from upds branch
- Repository: `https://github.com/termux-pacman/glibc-packages/tree/upds`

### Bun Binary Sources
- Primary: ARM64 musl build (`buno`)
- Fallback: Standard glibc build with grun compatibility

### Wrapper Architecture
The wrapper handles the specific failure in Bun's `configureEnvForRun()` function by:
1. Detecting `bun run <script>` commands
2. Parsing package.json directly  
3. Executing scripts with direct bun execution
4. Falling back to grun for everything else

## Contributing

1. Fork the repository
2. Test changes with the comprehensive test suite
3. Document any new issues or workarounds
4. Submit pull request

## License

MIT - See LICENSE file

---

**Status**: Working with limitations. Environment variable passing and some advanced features require workarounds due to Android/Termux constraints.