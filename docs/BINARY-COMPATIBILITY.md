# Binary Management Guide

This guide covers how to obtain, install, and manage Bun binaries for Termux.

## Why `buno` (Bun Original)

The binary is named `buno` (Bun Original) so the wrapper script can use the standard `bun` command name. This allows:
- Natural `bun` command usage
- Wrapper to handle Android/Termux-specific issues
- Direct binary access via `grun ~/.bun/bin/buno` when needed

## Current Binary Details

**Included Binary:**
- **Version**: Bun v1.2.20 ARM64 musl
- **Source**: Official Bun releases
- **Testing**: Verified working with glibc-runner v2.0-3
- **Location**: `~/.bun/bin/buno`

**Why musl over glibc:**
- Better compatibility with Android's bionic libc through glibc-runner
- Fewer dynamic library dependencies
- More predictable behavior in containerized/emulated environments

## Getting Official Binaries

### Download Latest Official Binary

```bash
# Use the included download script
cd /path/to/bun-on-termux
./scripts/download-official-bun.sh

# Manual download (what the script does)
LATEST_URL=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep "browser_download_url.*bun-linux-aarch64.zip" | cut -d '"' -f 4)
curl -L "$LATEST_URL" -o /tmp/bun-latest.zip
cd /tmp && unzip bun-latest.zip
chmod +x bun-linux-aarch64/bun
cp bun-linux-aarch64/bun ~/.bun/bin/buno
```

### Download Specific Version

```bash
# Replace v1.2.20 with desired version
VERSION="v1.2.20"
curl -L "https://github.com/oven-sh/bun/releases/download/$VERSION/bun-linux-aarch64.zip" -o /tmp/bun-$VERSION.zip
cd /tmp && unzip bun-$VERSION.zip
chmod +x bun-linux-aarch64/bun
cp bun-linux-aarch64/bun ~/.bun/bin/buno
```

## Setting Up glibc-runner

The binary requires glibc-runner to work on Termux:

```bash
# Install termux-pacman if not already installed
wget https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-aarch64.zip
unzip bootstrap-aarch64.zip && cd bootstrap
chmod +x bootstrap-aarch64.sh && ./bootstrap-aarch64.sh

# Install glibc-runner
pacman -S glibc-runner

# Verify installation
grun --version
```

## Wrapper Configuration

The wrapper script handles Android-specific issues automatically:

**Location**: `~/.bun/bin/bun` (shell script)
**Function**: 
- Calls `grun ~/.bun/bin/buno` with proper arguments
- Auto-adds `--backend=copyfile` for global installs
- Handles directory reading failures for `bun run`

**No additional configuration needed** - the wrapper should work automatically.

## Binary Testing Commands

After installing a new binary, verify it works:

### Basic Functionality
```bash
# Test direct binary
grun ~/.bun/bin/buno --version
grun ~/.bun/bin/buno --revision

# Test through wrapper  
bun --version
bun -e 'console.log("Hello from Bun")'
```

### Package Management
```bash
# Test local install
mkdir /tmp/test-bun && cd /tmp/test-bun
echo '{}' > package.json
bun add lodash

# Test global install (uses copyfile backend automatically)
bun i -g cowsay

# Test script execution
echo '{"scripts":{"test":"echo test works"}}' > package.json
bun run test
```

### TypeScript & Build
```bash
# Test TypeScript
echo 'const msg: string = "TypeScript works"; console.log(msg);' > test.ts
bun test.ts

# Test build
echo 'export default "built successfully";' > entry.js  
bun build entry.js --outdir=dist
```

## Common Issues & Solutions

### Binary Won't Execute
**Check architecture:**
```bash
file ~/.bun/bin/buno
# Should show: ARM 64-bit
```

**Verify grun setup:**
```bash
grun --version
# Should show glibc-runner version
```

### Permission Errors During Install
**For global installs** (wrapper auto-handles):
```bash
# Wrapper automatically adds --backend=copyfile for -g flag
bun i -g package-name
```

**For local installs with issues:**
```bash
bun install --backend=copyfile
```

### Directory Reading Errors
**The wrapper handles this automatically**, but if needed:
```bash
# Instead of: bun run script
# Use: bun path/to/script.js directly
```

## Manual Binary Replacement

To replace the binary manually:

```bash
# Backup current binary
cp ~/.bun/bin/buno ~/.bun/bin/buno.backup.$(date +%s)

# Replace with new binary (make sure it's ARM64)
cp /path/to/new/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Test new binary
bun --version

# If it fails, restore backup
cp ~/.bun/bin/buno.backup.* ~/.bun/bin/buno
```

## Verification Script

Run the comprehensive test suite to verify any binary:

```bash
cd /path/to/bun-on-termux
./test-bun-comprehensive.sh
```

This tests 60+ scenarios and provides a detailed compatibility report.