#!/data/data/com.termux/files/usr/bin/bash
# Bun on Termux Setup Script
# Builds C components and installs working Bun with userland exec

set -e

echo "Setting up Bun on Termux"
echo "========================"

# Check prerequisites
echo "Checking prerequisites..."
command -v git >/dev/null || { echo "ERROR: git not found. Run: pkg install git"; exit 1; }
command -v clang >/dev/null || { echo "ERROR: clang not found. Run: pkg install clang"; exit 1; }

# Check for pacman and glibc-runner
if ! command -v pacman >/dev/null; then
    echo "ERROR: pacman not found. You need to install termux-pacman first."
    echo "  See: https://github.com/termux-pacman/termux-packages"
    exit 1
fi

if ! command -v grun >/dev/null; then
    echo "Installing glibc-runner..."
    if pacman -S glibc-runner --noconfirm; then
        echo "OK: glibc-runner installed"
    else
        echo "ERROR: Failed to install glibc-runner."
        echo "  See: https://github.com/termux-pacman/glibc-packages/wiki"
        exit 1
    fi
else
    echo "OK: glibc-runner already installed"
fi

# Verify glibc headers are available
if [ ! -d "/data/data/com.termux/files/usr/glibc/include" ]; then
    echo "ERROR: glibc headers not found. Install glibc-dev:"
    echo "  pacman -S glibc"
    exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p ~/.bun/bin ~/.bun/lib ~/.bun/tmp/fake-root
mkdir -p ~/.config

# Build C components
echo "Building C components..."
if make all; then
    echo "OK: C components built"
else
    echo "ERROR: Build failed. Check clang and glibc installation."
    exit 1
fi

# Install C components
echo "Installing C components..."
cp bun-termux ~/.bun/bin/
cp bun-shim.so ~/.bun/lib/
chmod +x ~/.bun/bin/bun-termux

# Copy binaries
echo "Installing Bun components..."
cp binaries/* ~/.bun/bin/ 2>/dev/null || echo "  (no binaries to copy)"
chmod +x ~/.bun/bin/buno 2>/dev/null || true

# Copy wrappers
cp wrappers/bun ~/.bun/bin/bun-minimal
cp wrappers/bunx ~/.bun/bin/
chmod +x ~/.bun/bin/bun-minimal ~/.bun/bin/bunx

# Create bun symlink if needed
if [ ! -L ~/.bun/bin/bun ] || [ "$(readlink ~/.bun/bin/bun)" != "bun-minimal" ]; then
    ln -sf bun-minimal ~/.bun/bin/bun
fi

# Copy configuration
cp config/bunfig.toml ~/.bun/bin/

# Keep env-preload.js as legacy fallback
cp wrappers/env-preload.js ~/.bun/bin/ 2>/dev/null || true

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.bun/bin"; then
    echo "Adding to PATH..."
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
    echo "  Run 'source ~/.bashrc' or restart your shell"
fi

# Test installation
echo "Testing installation..."
export PATH="$HOME/.bun/bin:$PATH"
if ~/.bun/bin/bun --version >/dev/null 2>&1; then
    echo "OK: Bun installation successful"
    echo "  Version: $(~/.bun/bin/bun --version)"
else
    echo "ERROR: Installation may have issues"
    echo "  Try: ~/.bun/bin/bun-termux --version"
fi

# Test C wrapper directly
if ~/.bun/bin/bun-termux --version >/dev/null 2>&1; then
    echo "OK: C wrapper working"
else
    echo "WARN: C wrapper test failed, falling back to grun"
fi

echo
echo "Setup complete"
echo "  Run 'bash tests/run-tests.sh' to test all functionality"
echo "  See README.md for usage and troubleshooting"
