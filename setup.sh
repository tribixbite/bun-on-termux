#!/data/data/com.termux/files/usr/bin/bash
# Bun on Termux Setup Script
# Installs working Bun with glibc-runner compatibility

set -e

echo "🥟 Setting up Bun on Termux"
echo "=========================="

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v git >/dev/null || { echo "❌ git not found. Run: pkg install git"; exit 1; }

# Check for pacman and glibc-runner
if ! command -v pacman >/dev/null; then
    echo "❌ pacman not found. You need to install termux-pacman first."
    echo "📖 See: https://github.com/termux-pacman/termux-packages"
    echo "   Run the bootstrap installation script from that repository"
    exit 1
fi

if ! command -v grun >/dev/null; then
    echo "📦 Installing glibc-runner..."
    if pacman -S glibc-runner --noconfirm; then
        echo "✅ glibc-runner installed successfully"
    else
        echo "❌ Failed to install glibc-runner. Make sure gpkg repository is configured."
        echo "📖 See: https://github.com/termux-pacman/glibc-packages/wiki"
        exit 1
    fi
else
    echo "✅ glibc-runner already installed"
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p ~/.bun/bin
mkdir -p ~/.config

# Copy binaries
echo "📋 Installing Bun components..."
cp binaries/* ~/.bun/bin/ 2>/dev/null || echo "ℹ️  No binaries to copy"
cp wrappers/bun ~/.bun/bin/
cp wrappers/bunx ~/.bun/bin/
cp wrappers/bun-minimal ~/.bun/bin/
chmod +x ~/.bun/bin/*

# Copy configuration
cp config/bunfig.toml ~/

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.bun/bin"; then
    echo "🔧 Adding to PATH..."
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
    echo "ℹ️  Run 'source ~/.bashrc' or restart your shell"
fi

# Test installation
echo "🧪 Testing installation..."
export PATH="$HOME/.bun/bin:$PATH"
if ~/.bun/bin/bun --version >/dev/null 2>&1; then
    echo "✅ Bun installation successful!"
    echo "   Version: $(~/.bun/bin/bun --version)"
else
    echo "❌ Installation may have issues"
fi

echo
echo "🎉 Setup complete!"
echo "   Run './test-bun-comprehensive.sh' to test all functionality"
echo "   See README.md for usage and troubleshooting"