# Binary Patching Guide for Bun on Termux

This guide covers how to patch and configure glibc binaries to work with glibc-runner in Termux.

## Overview

Termux uses bionic libc (Android's C library), while many binaries (including Bun) are compiled for glibc (GNU C Library). The glibc-runner (grun) provides a compatibility layer that allows glibc binaries to run on Android by:

1. **ELF Header Patching**: Modifies binary headers for compatibility
2. **Dynamic Linker Setup**: Provides glibc environment 
3. **Library Resolution**: Finds and loads required glibc libraries
4. **System Call Translation**: Handles differences between glibc and bionic

## glibc-runner Commands

### Essential Commands

```bash
# Configure binary for device compatibility
grun --configure ./binary

# Find required libraries for binary  
grun --findlib ./binary

# Debug binary execution with strace
grun --debug [1|2|3|4] ./binary

# Launch glibc shell environment
grun --shell

# Enable termux-exec-glibc integration
grun --teg [command]

# Run binary without dynamic linker
grun --no-linker ./binary
```

### Configuration Process

#### 1. Initial Binary Analysis
```bash
# Check binary type and requirements
file ./binary

# Expected output for ARM64 glibc binary:
# ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), 
# dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, 
# for GNU/Linux 3.7.0, not stripped
```

#### 2. Binary Configuration
```bash
# Configure the binary for Termux compatibility
grun --configure ./binary

# This command:
# - Patches ELF headers for Android compatibility
# - Sets up dynamic linker paths
# - Configures library search paths
# - Usually runs silently on success
```

#### 3. Library Resolution
```bash
# Find and verify all required libraries
grun --findlib ./binary

# Success output:
# Message from glibc-runner: searching for libraries...
# Message from glibc-runner: searching libraries was successful

# Failure indicates missing dependencies that need to be installed
```

#### 4. Test Execution
```bash
# Test basic execution
grun ./binary --version

# Debug execution if issues occur
grun --debug 2 ./binary --version
```

## Bun Binary Patching Status

### Current buno Binary

The included `~/.bun/bin/buno` binary has been pre-configured:

```bash
# Binary information
file ~/.bun/bin/buno
# Output: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), 
#         dynamically linked, interpreter /lib/ld-linux-aarch64.so.1

# Configuration status
grun --configure ~/.bun/bin/buno  # Runs silently (already configured)

# Library verification  
grun --findlib ~/.bun/bin/buno    # Libraries found successfully

# Test execution
grun ~/.bun/bin/buno --version    # Works: Bun 1.3.9
```

**Result**: The included `buno` binary is already patched and configured for Termux.

## Manual Binary Patching Process

### For New Bun Binaries

If you download a fresh Bun binary from GitHub, follow this process:

#### 1. Download ARM64 glibc Binary
```bash
# Download latest ARM64 glibc binary from GitHub
# URL format: https://github.com/oven-sh/bun/releases/download/bun-v{version}/bun-linux-aarch64.zip

wget https://github.com/oven-sh/bun/releases/download/bun-v1.3.9/bun-linux-aarch64.zip
unzip bun-linux-aarch64.zip
```

#### 2. Verify Binary Type
```bash
# Check the downloaded binary
file ./bun-linux-aarch64/bun

# Expected: ARM64 executable, but may need patching for Android
```

#### 3. Configure for Termux
```bash
# Copy to working location
cp ./bun-linux-aarch64/bun ~/.bun/bin/bun-new

# Configure for Termux compatibility
grun --configure ~/.bun/bin/bun-new

# Verify libraries
grun --findlib ~/.bun/bin/bun-new

# Test execution
grun ~/.bun/bin/bun-new --version
```

#### 4. Replace Working Binary (if successful)
```bash
# Backup current working binary
cp ~/.bun/bin/buno ~/.bun/bin/buno.backup

# Replace with new binary
mv ~/.bun/bin/bun-new ~/.bun/bin/buno

# Test wrapper functionality
bun --version
```

## Troubleshooting Binary Issues

### Segmentation Faults

**Symptom**: Binary crashes with segfault
```bash
grun ./binary
# Segmentation fault
```

**Solutions**:
1. **Debug with strace**: `grun --debug 2 ./binary`
2. **Try different debug levels**: `grun --debug [1-4] ./binary`
3. **Check library dependencies**: `grun --findlib ./binary`
4. **Try without dynamic linker**: `grun --no-linker ./binary`

### Missing Libraries

**Symptom**: Library search fails
```bash
grun --findlib ./binary
# Message from glibc-runner: searching libraries was failed
```

**Solutions**:
1. **Install glibc packages**: `pacman -S glibc-runner glibc`
2. **Update glibc-runner**: `pacman -Syu glibc-runner`
3. **Check library paths**: `grun --shell` then `ldd ./binary`

### Configuration Failures

**Symptom**: Configuration command fails
```bash
grun --configure ./binary
# Error messages or crashes
```

**Solutions**:
1. **Check binary format**: `file ./binary`
2. **Ensure ARM64 architecture**: Binary must be `aarch64`
3. **Verify permissions**: `chmod +x ./binary`
4. **Try with sudo**: May need elevated permissions in some cases

## Binary Compatibility Notes

### Working Binaries
- **Bun v1.3.9 ARM64 glibc**: ✅ Works with glibc-runner
- **Node.js ARM64 glibc**: ✅ Usually works with configuration
- **Go binaries (ARM64)**: ✅ Often work without configuration

### Problematic Binaries  
- **x86/x64 binaries**: ❌ Architecture mismatch, won't work
- **Static binaries with Android incompatibilities**: ❌ May segfault
- **Binaries with kernel version requirements > Android**: ⚠️ May fail

### Alternatives for Failed Binaries
1. **Use glibc variant**: `bun-linux-aarch64.zip` (not musl) works with grun
2. **Compile from source**: Use Android NDK or cross-compilation
3. **Find ARM64-specific builds**: Check project releases for Android/ARM64
4. **Use JavaScript/TypeScript alternatives**: Run with Bun directly

## GitHub Release URLs for Bun

### Official Bun Releases
```bash
# Latest release URL pattern
https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip

# Specific version URL pattern  
https://github.com/oven-sh/bun/releases/download/bun-v{VERSION}/bun-linux-aarch64.zip

# Examples:
https://github.com/oven-sh/bun/releases/download/bun-v1.3.9/bun-linux-aarch64.zip
https://github.com/oven-sh/bun/releases/download/bun-v1.2.20/bun-linux-aarch64.zip
```

### Download and Patch Script
```bash
#!/bin/bash
# download-and-patch-bun.sh

VERSION=${1:-"v1.3.9"}
URL="https://github.com/oven-sh/bun/releases/download/bun-${VERSION}/bun-linux-aarch64.zip"

echo "Downloading Bun ${VERSION}..."
wget "$URL" -O "bun-${VERSION}.zip"

echo "Extracting..."
unzip "bun-${VERSION}.zip"

echo "Configuring for Termux..."
grun --configure "./bun-linux-aarch64/bun"

echo "Verifying libraries..."
if grun --findlib "./bun-linux-aarch64/bun"; then
    echo "Testing execution..."
    if grun "./bun-linux-aarch64/bun" --version; then
        echo "✅ Binary ready for use"
        echo "Install with: cp ./bun-linux-aarch64/bun ~/.bun/bin/buno"
    else
        echo "❌ Binary execution failed"
    fi
else
    echo "❌ Library verification failed"
fi
```

## Integration with Setup Scripts

### Current Setup Process
The `setup.sh` script in this repository:
1. **Downloads pre-configured buno**: Uses working binary from repository
2. **Sets up wrappers**: Installs enhanced Bun/bunx wrappers
3. **Configures environment**: Sets PATH and bunfig.toml

### Alternative: Fresh Binary Setup
To use a fresh GitHub binary instead:
```bash
# Replace the download section in setup.sh:
# Instead of: wget [repo-binary-url]
# Use: wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip
# Then add patching commands after extraction
```

## Advanced Configuration

### Custom grun Configuration
```bash
# Enable termux-exec-glibc integration
grun --teg

# Run with custom environment
env CUSTOM_VAR=value grun ./binary

# Debug with different strace levels
grun --debug 1 ./binary  # Basic debugging  
grun --debug 4 ./binary  # Verbose debugging
```

### Binary Optimization
```bash
# Strip debug symbols to reduce size
strip ./binary

# Check reduced size
ls -lh ./binary

# Test still works
grun ./binary --version
```

## Verification Checklist

After patching any new binary:

- [ ] Binary is ARM64 architecture (`file ./binary`)
- [ ] Configuration runs without errors (`grun --configure ./binary`)
- [ ] Library search succeeds (`grun --findlib ./binary`)
- [ ] Basic execution works (`grun ./binary --version`)
- [ ] Wrapper integration works (`bun --version` if replacing buno)
- [ ] Complex operations work (package installation, script execution)

## Conclusion

The glibc-runner patching process is essential for running glibc binaries in Termux. The included `buno` binary has been pre-configured and tested, but this guide enables you to patch fresh binaries from GitHub or other sources.

**Key Points**:
- Use `grun --configure` to patch new binaries
- Verify with `grun --findlib` before deployment  
- Test thoroughly before replacing working binaries
- Keep backups of known-working binaries