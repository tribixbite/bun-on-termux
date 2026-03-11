# Installation Guide

Complete guide for installing Bun on Termux Android.

## Prerequisites

### System Requirements
- **Android 7+** (API level 24+)
- **Termux app** from F-Droid or GitHub (NOT Google Play Store)
- **ARM64 (aarch64) architecture**
- **clang** compiler (for building C components)
- **~300MB free space**

### Package Manager Setup

This project requires **termux-pacman** for glibc support.

```bash
# Install termux-pacman if not already present
# See: https://github.com/termux-pacman/termux-packages

# Verify pacman is working
pacman --version
pacman -Sy  # Update package database
```

### Install Dependencies

```bash
# glibc-runner provides the glibc dynamic linker
pacman -S glibc-runner glibc

# clang is needed to build the C wrapper and shim
pkg install clang git
```

## Installation

### Automatic (Recommended)

```bash
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux
chmod +x setup.sh && ./setup.sh
```

This will:
1. Build the C wrapper (`bun-termux`) and LD_PRELOAD shim (`bun-shim.so`)
2. Install to `~/.bun/bin/` and `~/.bun/lib/`
3. Copy the wrapper script, config, and binary
4. Add `~/.bun/bin` to PATH
5. Run a quick verification

### Manual Installation

```bash
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux

# Build C components
make all

# Create directories
mkdir -p ~/.bun/{bin,lib,tmp/fake-root}

# Install C components
cp bun-termux ~/.bun/bin/
cp bun-shim.so ~/.bun/lib/
chmod +x ~/.bun/bin/bun-termux

# Install wrapper and config
cp wrappers/bun ~/.bun/bin/bun-minimal
ln -sf bun-minimal ~/.bun/bin/bun
cp config/bunfig.toml ~/.bun/bin/

# Download bun binary (if not included)
BUN_VERSION="1.3.10"
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Add to PATH
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
bun --version
```

## Binary Sources

### Included Binary
The repository includes a working ARM64 glibc binary (`buno`) pre-tested with the C wrapper.

### Official Releases
Download from [oven-sh/bun releases](https://github.com/oven-sh/bun/releases):

```bash
bash scripts/download-official-bun.sh 1.3.10
```

Always use `bun-linux-aarch64.zip` (glibc variant), **not** musl.

## Post-Installation

### Verify
```bash
bun --version                    # Should show version
bun -e 'console.log("works")'   # Should print "works"
bun -e 'console.log(Object.keys(process.env).length)'  # Should show 90+
```

### Run Tests
```bash
bash tests/run-tests.sh
```

### Troubleshooting
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

## Upgrading Bun

```bash
bash scripts/download-official-bun.sh <version>
# or manually:
cp ~/.bun/bin/buno ~/.bun/bin/buno.$(bun --version).bak
# download new binary, copy to ~/.bun/bin/buno
```

## Uninstallation

```bash
rm -rf ~/.bun/
# Remove PATH line from ~/.bashrc
```
