# Termux Configuration Documentation

## System Information

**Template**: Termux system configuration reference
**Requirements**: Android 7+ with aarch64 (ARM64) architecture
**Termux Source**: F-Droid or GitHub releases (NOT Google Play Store)
**Package Manager**: termux-pacman (required for glibc-runner)

## Package Manager Configuration

### Switching to Pacman (termux-pacman)
Termux has transitioned from `pkg` (apt-based) to `pacman` (Arch Linux package manager). See [Termux Wiki: Switching Package Manager](https://wiki.termux.com/wiki/Switching_package_manager) for details.

### Primary Package Manager: Pacman
- **Active Manager**: `pacman` (via TERMUX_APP_PACKAGE_MANAGER)
- **Format**: `pacman` (via TERMUX_MAIN_PACKAGE_FORMAT)
- **Configuration File**: `/data/data/com.termux/files/usr/etc/pacman.conf`

### Repository Sources

```ini
[main]         - Core Termux packages
[x11]          - X11/GUI packages  
[root]         - Root/system packages
[tur]          - Termux User Repository
[tur-continuous] - Continuous integration builds
[tur-multilib] - Multilib packages
[gpkg]         - Glibc packages (termux-pacman glibc-runner)
```

### Mirror Servers (Priority Order)
1. **Primary**: `https://service.termux-pacman.dev/$repo/$arch`
2. **Vietnam**: `https://mirror.meowsmp.net/termux-pacman/$repo/$arch`  
3. **Germany**: `https://ftp.agdsn.de/termux-pacman/$repo/$arch`

## Complete Pacman Usage Guide

### Essential Commands

#### Basic Operations
```bash
# Update package database
pacman -Sy

# Update package database and upgrade all packages
pacman -Syu

# Install a package
pacman -S package-name

# Install multiple packages
pacman -S package1 package2 package3

# Remove a package
pacman -R package-name

# Remove package with dependencies not required by other packages
pacman -Rs package-name

# Remove package with config files
pacman -Rn package-name
```

#### Package Search & Information
```bash
# Search for packages
pacman -Ss search-term

# Search installed packages
pacman -Qs search-term

# Show package information
pacman -Si package-name

# Show installed package information
pacman -Qi package-name

# List all installed packages
pacman -Q

# List explicitly installed packages
pacman -Qe

# List orphan packages (dependencies no longer needed)
pacman -Qdt

# List files installed by package
pacman -Ql package-name

# Find which package owns a file
pacman -Qo /path/to/file
```

#### Advanced Operations
```bash
# Force reinstall package
pacman -S --overwrite='*' package-name

# Install local package file
pacman -U package-file.pkg.tar.xz

# Download package without installing
pacman -Sw package-name

# Clean package cache (keep 1 version)
pacman -Sc

# Clean entire package cache
pacman -Scc

# Check for broken dependencies
pacman -Dk

# Verify package files
pacman -Qk package-name
```

### Tips and Tricks

#### Handling Conflicts
```bash
# When encountering file conflicts during upgrade
pacman -Syu --overwrite='*'

# For specific file conflicts
pacman -S package-name --overwrite='/path/to/conflicting/file'
```

#### Package Groups
```bash
# Install entire package group
pacman -S base-devel

# List packages in a group
pacman -Sg base-devel

# Install group excluding specific packages
pacman -S base-devel --ignore=package-to-skip
```

#### Maintenance Tasks
```bash
# Remove all orphan packages
pacman -Rns $(pacman -Qtdq)

# List packages by install size
pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h

# List recently installed packages
expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort | tail -20

# Backup package list
pacman -Qqe > packages.txt

# Restore packages from list
pacman -S --needed - < packages.txt
```

#### Useful Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc
alias pacs='pacman -Ss'       # Search packages
alias paci='pacman -S'        # Install package
alias pacr='pacman -Rs'       # Remove package with deps
alias pacu='pacman -Syu'      # Full system upgrade
alias pacq='pacman -Q'        # Query installed packages
alias pacf='pacman -Ql'       # List package files
alias paco='pacman -Qdt'      # List orphans
alias pacc='pacman -Scc'      # Clean cache
```

### Common Package Installations

#### Development Tools
```bash
# Version control
pacman -S git gh

# Build essentials
pacman -S base-devel cmake ninja

# Languages and runtimes
pacman -S python nodejs rust golang

# Editors
pacman -S vim neovim emacs nano
```

#### System Utilities
```bash
# Network tools
pacman -S openssh wget curl nmap net-tools

# File management
pacman -S rsync rclone fzf ripgrep fd

# System monitoring
pacman -S htop btop ncdu neofetch

# Compression
pacman -S zip unzip tar p7zip
```

#### Remote Access (SSH)
```bash
# Install OpenSSH
pacman -S openssh

# Start SSH daemon
sshd

# Configure SSH (optional)
# Edit ~/.ssh/sshd_config for custom settings

# Set password for remote access
passwd

# Get device IP address
ip addr show | grep inet

# Connect from another device
# ssh -p 8022 username@device-ip
```

### Troubleshooting Pacman Issues

#### Database Lock
```bash
# If pacman is locked (another instance running)
rm /data/data/com.termux/files/usr/var/lib/pacman/db.lck
```

#### Corrupted Database
```bash
# Refresh all package databases
rm -rf /data/data/com.termux/files/usr/var/lib/pacman/sync
pacman -Syy
```

#### Key Issues
```bash
# Refresh pacman keys
pacman-key --init
pacman-key --populate
```

#### Mirror Issues
```bash
# Edit mirror configuration
nano /data/data/com.termux/files/usr/etc/pacman.conf
# Comment out problematic mirrors or reorder them
```

## Glibc Integration

### Glibc-Runner (grun) v2.0-3  
- **Purpose**: Execute glibc-based binaries on Android bionic libc
- **Installation**: `pacman -S glibc-runner` (from upds branch packages)
- **Binary Location**: `/data/data/com.termux/files/usr/bin/grun`
- **Glibc Root**: `/data/data/com.termux/files/usr/glibc/`
- **Repository Source**: `upds` branch of termux-pacman/glibc-packages (latest fixes)

### Glibc-Runner Usage Commands
```bash
# Launch glibc shell environment
grun --shell

# Execute glibc binary directly  
grun ./binary-name

# Configure binary for device compatibility
grun --configure ./binary-name

# Find required libraries for binary
grun --findlib ./binary-name

# Debug binary execution with strace
grun --debug [1|2|3|4] ./binary-name

# Enable termux-exec-glibc integration
grun --teg [command]
```

## Termux-Exec Configuration

### Environment Variables
- **LD_PRELOAD**: `/data/data/com.termux/files/usr/lib/libtermux-exec-ld-preload.so`
- **Purpose**: Intercept execution calls to handle Android restrictions
- **Key Functions**: Path normalization, library loading, execute permission workarounds

### Configurable Options (if needed)
```bash
# System Linker Exec Solution control
export TERMUX_EXEC__SYSTEM_LINKER_EXEC__MODE=[value]

# Execve call interception control  
export TERMUX_EXEC__EXECVE_CALL__INTERCEPT=[value]

# Logging verbosity control
export TERMUX_EXEC__LOG_LEVEL=[1-4]
```

## Bun Runtime Configuration

### Installation Structure
```
~/.bun/bin/
├── bun                # Wrapper script (bash, handles CWD + env + routing)
├── buno               # Real Bun binary (v1.3.9, ~100MB glibc aarch64)
├── env-preload.js     # Preload: restores process.env from /proc/self/environ
└── bunfig.toml        # Config: copyfile backend, preload, Termux defaults
```

### Wrapper Architecture

The wrapper (`~/.bun/bin/bun`, source: `wrappers/bun-minimal`, ~137 lines) handles:

1. **Safe CWD**: Saves original directory, converts all file args to absolute paths, `cd`s to `~/.bun/tmp` before exec
2. **Env preload**: Passes `--preload env-preload.js` for JS/TS execution (restores process.env)
3. **`bun run` parsing**: Extracts scripts from package.json, routes `bun`-prefixed scripts through wrapper, `eval`s shell commands natively
4. **Global install fix**: Auto-adds `--backend=copyfile` for `-g` installs
5. **Config passthrough**: `--config=~/.bun/bin/bunfig.toml` on all commands
6. **Stderr filtering**: Suppresses "Cannot read directory" noise

#### Package Management
```bash
bun install       # bunfig.toml backend=copyfile is applied
bun add pkg       # bunfig.toml backend=copyfile is applied
bun i -g pkg      # wrapper adds --backend=copyfile explicitly
```

#### Build Process
- `bun build` works for bundling (not `--compile`)
- Custom build.sh scripts handle compilation limitations
- `bun run build` routes through wrapper's package.json parser

## Package Installation Verification

### Test Results
✅ **Package Manager**: `pacman -S screen` - SUCCESS
✅ **Package Execution**: `screen --version` - SUCCESS  
✅ **Repository Access**: All 7 repositories accessible
✅ **Dependency Resolution**: Automatic conflict resolution with `--overwrite`

### Common Package Commands
```bash
# Search for packages
pacman -Ss package-name

# Install package with conflict resolution
pacman -S package-name --overwrite='*'

# System upgrade
pacman -Syu

# List installed packages
pacman -Q

# Package information
pacman -Si package-name
```

## Development Environment Integration

### Node.js/JavaScript Runtime
- **Primary Runtime**: Bun v1.3.9 (ARM64 glibc via grun)
- **Package Manager**: Bun with enhanced Termux wrapper
- **Compatibility**: Full ES modules, CommonJS, TypeScript support
- **Performance**: Native execution speed via glibc-runner

### Project Build Systems
- **uwu**: Custom build.sh → `~/git/uwu/dist/uwu-cli`
- **opencode**: Custom build.sh → `~/git/opencode/dist/opencode`  
- **Approach**: Direct TypeScript execution vs problematic compilation

## Security and Compatibility Notes

### Android Security Model Integration  
- **App Data Execution**: Handled by termux-exec-ld-preload.so
- **Directory Access**: Restricted `/data/` paths require workarounds
- **Binary Execution**: glibc-runner provides compatibility layer

### File System Limitations
- **Compilation**: `bun build --compile` fails due to directory traversal restrictions
- **Workarounds**: Custom build scripts, direct source execution
- **Symlinks**: Function correctly within Termux environment

## Troubleshooting Guide

### Package Manager Issues
```bash
# Fix database conflicts
pacman -Syu --overwrite='*'

# Refresh package databases  
pacman -Sy

# Clear package cache
pacman -Scc
```

### Bun Execution Issues
```bash
# Test direct execution
grun ~/.bun/bin/buno --version

# Test wrapper functionality
bun --version

# Debug directory reading issues
bun run [script] --verbose
```

### Glibc Binary Issues  
```bash
# Configure binary for device
grun --configure ./binary

# Find missing libraries
grun --findlib ./binary

# Debug with strace
grun --debug 2 ./binary
```

## Environment Variables Summary

```bash
# Core Termux Configuration
export TERMUX_APP_PACKAGE_MANAGER="pacman"
export TERMUX_MAIN_PACKAGE_FORMAT="pacman"
export TERMUX__PREFIX="/data/data/com.termux/files/usr"
export TERMUX__HOME="/data/data/com.termux/files/home"

# Execution Environment
export LD_PRELOAD="/data/data/com.termux/files/usr/lib/libtermux-exec-ld-preload.so"

# Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

## System Status: FULLY FUNCTIONAL ✅

- **Package Manager**: Pacman with 7 active repositories
- **Glibc Integration**: glibc-runner v2.0-3 operational
- **JavaScript Runtime**: Bun v1.3.9 with enhanced Termux wrapper
- **Build Systems**: Custom solutions for compilation limitations
- **Package Installation**: Verified working with automatic conflict resolution

**Last Updated**: 2025-02-15
**Configuration Status**: Production Ready