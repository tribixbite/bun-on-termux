#!/data/data/com.termux/files/usr/bin/bash
# Bun on Termux Setup Script
# Installs working Bun with glibc-runner compatibility

set -e

echo "🥟 Setting up Bun on Termux"
echo "=========================="

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v git >/dev/null || { echo "❌ git not found. Run: pkg install git"; exit 1; }
command -v node >/dev/null || { echo "❌ node not found. Run: pkg install nodejs-lts"; exit 1; }

# Install glibc-runner if not present
if ! command -v grun >/dev/null; then
    echo "📦 Installing glibc-runner..."
    bash <(curl -s https://raw.githubusercontent.com/termux-pacman/glibc-packages/upds/install-glibc-runner.sh)
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