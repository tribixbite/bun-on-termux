#!/data/data/com.termux/files/usr/bin/bash
# Download Official Bun Binary Script
# Downloads the latest official Bun binary for ARM64 and installs it

set -e

echo "🥟 Official Bun Binary Downloader"
echo "================================="

# Check prerequisites
command -v curl >/dev/null || { echo "❌ curl not found. Run: pacman -S curl"; exit 1; }
command -v wget >/dev/null || { echo "❌ wget not found. Run: pacman -S wget"; exit 1; }
command -v grun >/dev/null || { echo "❌ grun not found. Install glibc-runner first"; exit 1; }

# Create directories
echo "📁 Creating directories..."
mkdir -p ~/.bun/bin
mkdir -p ~/.bun/downloads

# Get latest release info
echo "🔍 Finding latest Bun release..."
LATEST_URL=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep "browser_download_url.*bun-linux-aarch64.zip" | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "❌ Could not find latest ARM64 release URL"
    echo "📖 Please check: https://github.com/oven-sh/bun/releases"
    exit 1
fi

echo "📦 Found: $LATEST_URL"

# Download binary
echo "⬇️  Downloading official Bun binary..."
cd ~/.bun/downloads

# Remove old downloads
rm -f bun-latest-official.zip
rm -rf bun-linux-aarch64

# Download
if ! wget "$LATEST_URL" -O bun-latest-official.zip; then
    echo "❌ Download failed"
    exit 1
fi

# Extract
echo "📂 Extracting binary..."
if ! unzip -o bun-latest-official.zip; then
    echo "❌ Extraction failed"
    exit 1
fi

if [ ! -d "bun-linux-aarch64" ]; then
    echo "❌ Expected directory 'bun-linux-aarch64' not found"
    ls -la
    exit 1
fi

cd bun-linux-aarch64

if [ ! -f "bun" ]; then
    echo "❌ Bun binary not found in extracted files"
    ls -la
    exit 1
fi

# Backup existing binary if it exists
if [ -f ~/.bun/bin/buno ]; then
    echo "💾 Backing up existing binary..."
    cp ~/.bun/bin/buno ~/.bun/bin/buno.backup.$(date +%s)
fi

# Install new binary
echo "🔧 Installing binary..."
cp bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Test installation
echo "🧪 Testing installation..."
if grun ~/.bun/bin/buno --version; then
    echo "✅ Official Bun binary installed successfully!"
    
    # Test with wrapper if available
    if [ -f ~/.bun/bin/bun ]; then
        echo "🧪 Testing with wrapper..."
        if ~/.bun/bin/bun --version; then
            echo "✅ Wrapper integration working!"
        else
            echo "⚠️  Wrapper test failed, but binary works directly"
        fi
    fi
else
    echo "❌ Binary test failed"
    
    # Restore backup if available
    if [ -f ~/.bun/bin/buno.backup.* ]; then
        echo "🔄 Restoring backup binary..."
        BACKUP=$(ls -t ~/.bun/bin/buno.backup.* | head -n 1)
        cp "$BACKUP" ~/.bun/bin/buno
        echo "✅ Backup restored"
    fi
    exit 1
fi

# Get version info
BUN_VERSION=$(grun ~/.bun/bin/buno --version)
echo
echo "🎉 Installation Complete!"
echo "📋 Bun Version: $BUN_VERSION"
echo "📁 Binary Location: ~/.bun/bin/buno"
echo "📁 Download Cache: ~/.bun/downloads/"

# Cleanup option
echo
echo "🧹 Clean up download files? (y/N)"
read -t 10 -n 1 cleanup
echo
if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ]; then
    cd ~/.bun
    rm -rf downloads/bun-latest-official.zip downloads/bun-linux-aarch64
    echo "✅ Download files cleaned up"
fi

echo
echo "📖 Next steps:"
echo "   1. Test functionality: bun --version"
echo "   2. Run test suite: ./test-bun-comprehensive.sh"
echo "   3. Check compatibility: grun ~/.bun/bin/buno --help"
echo
echo "⚠️  Note: Official binaries may have different compatibility"
echo "   characteristics compared to the included pre-tested binary."