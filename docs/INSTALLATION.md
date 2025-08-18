# Installation Guide

Complete guide for installing Bun on Termux Android.

## Prerequisites

### System Requirements
- **Android 7+** (API level 24+)
- **Termux app** installed from F-Droid or GitHub (NOT Google Play Store)
- **ARM64 (aarch64) architecture** (most modern Android devices)
- **At least 200MB free space** for installation

### Package Manager Setup

This project requires **termux-pacman** instead of the default `pkg` manager.

#### Option 1: Fresh Termux Installation
If you're starting with a fresh Termux installation:

```bash
# Download and run the termux-pacman bootstrap
pkg update
pkg install wget
wget https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-aarch64.zip
unzip bootstrap-aarch64.zip
./bootstrap-aarch64.sh
```

#### Option 2: Existing Termux Installation
If you already have Termux set up:

```bash
# WARNING: This will replace your package manager
# Back up important data first

# Download termux-pacman bootstrap
pkg install wget
wget https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-aarch64.zip
unzip bootstrap-aarch64.zip

# IMPORTANT: This step replaces pkg with pacman
./bootstrap-aarch64.sh
```

#### Verify pacman installation
```bash
# Check that pacman is working
pacman --version
pacman -Sy  # Update package database
```

### Install glibc-runner

```bash
# Install glibc-runner (required for running glibc binaries)
pacman -S glibc-runner

# Verify installation
grun --version
```

## Bun Installation

### Automatic Installation (Recommended)

```bash
# Clone this repository
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux

# Run setup script
chmod +x setup.sh
./setup.sh

# Verify installation
bun --version
```

### Manual Installation

If you prefer to install manually:

```bash
# Clone repository
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux

# Create directories
mkdir -p ~/.bun/bin

# Copy binaries and wrappers
cp binaries/* ~/.bun/bin/
cp wrappers/bun ~/.bun/bin/
chmod +x ~/.bun/bin/*

# Copy configuration
cp config/bunfig.toml ~/

# Add to PATH
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test installation
bun --version
```

## Binary Sources

### Option 1: Included Binary (Recommended)
The repository includes a working ARM64 binary (`buno`) that's compatible with glibc-runner.

### Option 2: Official Bun Releases
If you prefer to obtain the binary from official sources:

#### Download Official ARM64 Binary
```bash
# Create download directory
mkdir -p ~/.bun/downloads
cd ~/.bun/downloads

# Download latest Bun for Linux ARM64
# Check https://github.com/oven-sh/bun/releases for latest version
BUN_VERSION="1.2.20"  # Update this to latest version
wget "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip"

# Extract binary
unzip "bun-linux-aarch64.zip"
cd "bun-linux-aarch64"

# Copy binary to our setup
cp bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Test compatibility with glibc-runner
grun ~/.bun/bin/buno --version
```

#### Automated Download Script
```bash
# Get latest release automatically
LATEST_URL=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep "browser_download_url.*bun-linux-aarch64.zip" | cut -d '"' -f 4)

# Download and install
mkdir -p ~/.bun/downloads
cd ~/.bun/downloads
wget "$LATEST_URL" -O bun-latest-aarch64.zip
unzip -o bun-latest-aarch64.zip
cd bun-linux-aarch64
cp bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Verify
grun ~/.bun/bin/buno --version
```

#### Verify Binary Compatibility
After downloading an official binary, test it:

```bash
# Test basic execution
grun ~/.bun/bin/buno --version

# Test with wrapper
bun --version

# Test package operations (might need copyfile backend)
echo '{}' > test-package.json
grun ~/.bun/bin/buno add lodash --backend=copyfile
```

**Note**: Official binaries may have different compatibility characteristics. The included binary is pre-tested for Termux/glibc-runner compatibility.

### Option 3: Building from Source (Advanced)
If you want to build Bun from source:

```bash
# This is complex and requires significant resources
# See: https://github.com/oven-sh/bun/blob/main/docs/building.md

# Prerequisites for building:
pacman -S cmake ninja clang llvm git nodejs-lts

# Clone Bun source
git clone https://github.com/oven-sh/bun.git
cd bun

# Install dependencies
npm install

# Configure for cross-compilation (experimental)
# Note: Building on Termux directly is not officially supported
make setup
make dev

# The resulting binary will need glibc-runner compatibility testing
```

**Warning**: Building from source is complex, resource-intensive, and may not work reliably on Termux. Cross-compilation from a desktop Linux system is recommended if you need a custom build.

## Post-Installation

### Configuration
```bash
# Copy global configuration (optional)
cp config/bunfig-global.toml ~/.bun/bunfig.toml
```

### Test Installation
```bash
# Run comprehensive tests
./test-bun-comprehensive.sh

# Quick functionality test
cd examples/basic-project
bun install
bun run dev
```

### Troubleshooting
If installation fails:

1. **Check architecture**: `uname -m` should show `aarch64`
2. **Verify pacman**: `pacman --version` should work
3. **Check grun**: `grun --version` should work
4. **Review logs**: Check error messages carefully
5. **See troubleshooting guide**: `docs/TROUBLESHOOTING.md`

## Alternative Installation Methods

### From Release
Download from GitHub releases instead of cloning:

```bash
# Download latest release
wget https://github.com/tribixbite/bun-on-termux/archive/refs/heads/main.zip
unzip main.zip
cd bun-on-termux-main
./setup.sh
```

### Manual Binary Installation
If you only need the wrapper and binary:

```bash
# Create directories
mkdir -p ~/.bun/bin

# Download and install binary (if you have a compatible one)
# Place your ARM64 musl bun binary as ~/.bun/bin/buno

# Download wrapper
wget https://raw.githubusercontent.com/tribixbite/bun-on-termux/main/wrappers/bun
chmod +x bun
mv bun ~/.bun/bin/

# Add to PATH
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Uninstallation

To completely remove Bun on Termux:

```bash
# Remove Bun files
rm -rf ~/.bun/

# Remove configuration
rm -f ~/bunfig.toml

# Remove from PATH (edit ~/.bashrc and remove the PATH line)
nano ~/.bashrc

# Remove glibc-runner (optional)
pacman -R glibc-runner
```

## Next Steps

After installation:
1. Read the main README.md for usage examples
2. Try the example project in `examples/basic-project/`
3. Run the test suite to verify functionality
4. See `docs/TROUBLESHOOTING.md` for common issues