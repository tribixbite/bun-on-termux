#!/data/data/com.termux/files/usr/bin/bash
# Download Official Bun Binary Script
# Downloads a specific or latest official Bun binary for ARM64 and installs it
# Usage: ./download-official-bun.sh [version]
#   version: e.g. "1.3.10" (default: latest)

set -e

echo "Official Bun Binary Downloader"
echo "=============================="

# Check prerequisites
command -v curl >/dev/null || { echo "ERROR: curl not found. Run: pacman -S curl"; exit 1; }
command -v wget >/dev/null || { echo "ERROR: wget not found. Run: pacman -S wget"; exit 1; }
command -v grun >/dev/null || { echo "ERROR: grun not found. Install glibc-runner first"; exit 1; }

# Create directories
echo "Creating directories..."
mkdir -p ~/.bun/bin
mkdir -p ~/.bun/downloads

# Determine version
BUN_TARGET_VERSION="${1:-}"

if [ -n "$BUN_TARGET_VERSION" ]; then
    echo "Fetching bun v${BUN_TARGET_VERSION}..."
    LATEST_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_TARGET_VERSION}/bun-linux-aarch64.zip"
else
    echo "Finding latest Bun release..."
    LATEST_URL=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep "browser_download_url.*bun-linux-aarch64.zip" | cut -d '"' -f 4)
fi

if [ -z "$LATEST_URL" ]; then
    echo "❌ Could not find latest ARM64 release URL"
    echo "📖 Please check: https://github.com/oven-sh/bun/releases"
    exit 1
fi

echo "URL: $LATEST_URL"

# Download binary
echo "Downloading official Bun binary..."
cd ~/.bun/downloads

# Remove old downloads
rm -f bun-latest-official.zip
rm -rf bun-linux-aarch64

# Download
if ! wget -q "$LATEST_URL" -O bun-latest-official.zip; then
    echo "ERROR: Download failed"
    exit 1
fi

# Extract
echo "Extracting binary..."
if ! unzip -o -q bun-latest-official.zip; then
    echo "ERROR: Extraction failed"
    exit 1
fi

if [ ! -d "bun-linux-aarch64" ]; then
    echo "ERROR: Expected directory 'bun-linux-aarch64' not found"
    ls -la
    exit 1
fi

cd bun-linux-aarch64

if [ ! -f "bun" ]; then
    echo "ERROR: Bun binary not found in extracted files"
    ls -la
    exit 1
fi

# Backup existing binary if it exists
if [ -f ~/.bun/bin/buno ]; then
    CURRENT_VER=$(grun ~/.bun/bin/buno --version 2>/dev/null || echo "unknown")
    echo "Backing up existing binary (v${CURRENT_VER})..."
    cp ~/.bun/bin/buno ~/.bun/bin/buno.${CURRENT_VER}.bak
fi

# Install new binary
echo "Installing binary..."
cp bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Test installation
echo "Testing installation..."
if grun ~/.bun/bin/buno --version; then
    echo "OK: Official Bun binary installed successfully"

    # Test with wrapper if available
    if [ -f ~/.bun/bin/bun ]; then
        echo "Testing with wrapper..."
        if ~/.bun/bin/bun --version; then
            echo "OK: Wrapper integration working"
        else
            echo "WARN: Wrapper test failed, but binary works directly"
        fi
    fi
else
    echo "ERROR: Binary test failed"

    # Restore backup if available
    BACKUP=$(ls -t ~/.bun/bin/buno.*.bak 2>/dev/null | head -n 1)
    if [ -n "$BACKUP" ]; then
        echo "Restoring backup binary..."
        cp "$BACKUP" ~/.bun/bin/buno
        echo "Backup restored"
    fi
    exit 1
fi

# Get version info
BUN_VERSION=$(grun ~/.bun/bin/buno --version)
echo
echo "Installation complete"
echo "  Version:  $BUN_VERSION"
echo "  Binary:   ~/.bun/bin/buno"
echo "  Download: ~/.bun/downloads/"

# Clean up download files
cd ~/.bun
rm -rf downloads/bun-latest-official.zip downloads/bun-linux-aarch64
echo "Download files cleaned up"

echo
echo "Next steps:"
echo "  1. Test: bun --version"
echo "  2. Run test suite: bash tests/run-tests.sh"