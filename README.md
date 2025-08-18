# Bun on Termux

Native Bun JavaScript runtime working on Termux Android using glibc-runner.

## Overview

This project provides a complete Bun runtime for Termux Android, enabling native JavaScript/TypeScript execution without container dependencies. It uses glibc-runner for compatibility with standard Bun binaries on Android's bionic libc system.

## Features

- ✅ **Direct Execution**: `bun script.js`, `bun script.ts` work natively
- ✅ **Package Management**: `bun install`, `bun add`, `bun remove` with automatic optimizations
- ✅ **Global Packages**: `bun i -g package` with automatic copyfile backend
- ✅ **Script Running**: `bun run dev` with wrapper-based parsing
- ✅ **Build System**: `bun build` and bundling operations
- ✅ **TypeScript Support**: Built-in TypeScript compilation and execution
- ⚠️ **Environment Variables**: Limited due to glibc-runner design constraints
- ⚠️ **Compilation**: Some `bun build --compile` features may be restricted

## Installation

### Prerequisites

**Required**: termux-pacman (replaces default pkg manager)

#### Install termux-pacman
```bash
# For fresh Termux installations:
pkg install wget
wget https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-aarch64.zip
unzip bootstrap-aarch64.zip
./bootstrap-aarch64.sh

# Verify installation
pacman --version
```

#### Install dependencies
```bash
# Update package database
pacman -Sy

# Install required packages
pacman -S git glibc-runner

# Verify glibc-runner
grun --version
```

### Install Bun on Termux

```bash
# Clone repository
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux

# Run setup
chmod +x setup.sh
./setup.sh

# Verify installation
bun --version
```

### Test Installation

```bash
# Run comprehensive test suite
./test-bun-comprehensive.sh

# Try example project
cd examples/basic-project
bun install
bun run dev
```

## Quick Start

### Basic Usage
```bash
# Direct file execution
echo 'console.log("Hello from Bun!");' > hello.js
bun hello.js

# TypeScript support
echo 'const message: string = "TypeScript works!"; console.log(message);' > hello.ts
bun hello.ts

# Package management
bun init
bun add lodash
bun install
```

### Project Scripts
```bash
# package.json scripts work automatically
bun run dev
bun run build
bun run test

# Global package installation
bun i -g prettier
bun i -g typescript
```

## Architecture

### Core Components

1. **glibc-runner (grun)**: Compatibility layer for glibc binaries on Android
2. **Bun Binary (buno)**: ARM64 musl-based Bun runtime (92MB)
3. **Wrapper Script**: Handles Android-specific filesystem and directory issues
4. **Configuration**: Global bunfig.toml with Termux-optimized settings

### Execution Flow
```
Direct: bun script.js → wrapper → grun → buno → execution
Scripts: bun run dev → wrapper → parse package.json → direct execution
Global: bun i -g pkg → wrapper → grun → buno --backend=copyfile
```

## File Structure

- `wrappers/bun` - Main wrapper with Android compatibility fixes
- `wrappers/bun-minimal` - Minimal wrapper for testing
- `binaries/buno` - Working ARM64 Bun binary (92MB)
- `config/bunfig.toml` - Local project configuration template
- `config/bunfig-global.toml` - Global configuration template
- `test-bun-comprehensive.sh` - Complete test suite (40+ tests)
- `examples/` - Working example projects
- `docs/` - Complete documentation and troubleshooting

## Binary Options

### Included Binary (Default)
The repository includes a pre-tested ARM64 binary that's verified to work with glibc-runner.

### Official Bun Binary (Alternative)
If you prefer to use the latest official Bun binary:

#### Automated Script (Recommended)
```bash
# Use the provided download script
chmod +x scripts/download-official-bun.sh
./scripts/download-official-bun.sh
```

#### Manual Download
```bash
# Download latest official Bun for ARM64
LATEST_URL=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep "browser_download_url.*bun-linux-aarch64.zip" | cut -d '"' -f 4)
mkdir -p ~/.bun/downloads && cd ~/.bun/downloads
wget "$LATEST_URL" -O bun-latest.zip
unzip -o bun-latest.zip && cd bun-linux-aarch64
cp bun ~/.bun/bin/buno && chmod +x ~/.bun/bin/buno

# Test compatibility
grun ~/.bun/bin/buno --version
```

**Note**: Official binaries may have different compatibility characteristics. The download script includes automatic testing and backup/restore functionality. See `docs/INSTALLATION.md` for detailed instructions.

## Known Limitations

### Environment Variables
glibc-runner doesn't pass environment variables to child processes. Workarounds:
- Use configuration files instead of environment variables
- Create wrapper scripts that set variables explicitly
- Hardcode values in application code

### Directory Reading
Some `bun run` operations require wrapper intervention due to Android filesystem restrictions. The wrapper handles this transparently.

### Build Compilation
`bun build --compile` may have limitations on ARM64 Android. Use regular bundling as an alternative.

## Troubleshooting

### Common Issues

**"CouldntReadCurrentDirectory" Error**
- **Cause**: Android filesystem restrictions
- **Solution**: Use the provided wrapper (automatic)

**Global Install Permission Errors**
- **Cause**: Default hardlink backend doesn't work on Android
- **Solution**: Wrapper automatically adds `--backend=copyfile`

**Environment Variables Missing**
- **Cause**: glibc-runner limitation
- **Solution**: Use config files or wrapper scripts

**Segmentation Faults**
- **Cause**: Binary compatibility issues
- **Solution**: Ensure using included `buno` binary

### Getting Help

1. Run the test suite: `./test-bun-comprehensive.sh`
2. Check logs and error messages
3. Review `docs/TROUBLESHOOTING.md`
4. Check system requirements and installation steps

## Development

### Testing
```bash
# Full test suite
./test-bun-comprehensive.sh

# Quick functionality test
bun --version
bun -e 'console.log("Works!")'
```

### Contributing
1. Fork the repository
2. Test changes with the comprehensive test suite
3. Update documentation for any changes
4. Submit pull request with detailed description

## Technical Details

- **Binary Source**: ARM64 musl build compatible with glibc-runner
- **glibc-runner Version**: v2.0+ with upds branch support
- **Architecture**: ARM64 (aarch64) Android devices
- **Wrapper Logic**: Handles directory reading, global installs, script parsing
- **Performance**: Near-native execution speed with ~10MB memory overhead

## Support

- **Documentation**: Complete guides in `docs/`
- **Examples**: Working projects in `examples/`
- **Issues**: Report bugs via GitHub issues
- **Architecture**: See `docs/ARCHITECTURE.md` for technical details

## License

MIT - See LICENSE file for details.

---

**Status**: Production ready with documented limitations. Actively maintained and tested on ARM64 Android devices.