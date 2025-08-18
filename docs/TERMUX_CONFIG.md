# Termux Configuration Documentation

## System Information

**Template**: Termux system configuration reference
**Requirements**: Android 7+ with aarch64 (ARM64) architecture
**Termux Source**: F-Droid or GitHub releases (NOT Google Play Store)
**Package Manager**: termux-pacman (required for glibc-runner)

## Package Manager Configuration

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
├── bun -> bun.glibc.sh           # Main entry point (symlink)
├── bun.glibc.sh                  # Enhanced wrapper script  
├── buno                          # Working Bun binary (92MB musl)
├── bunx                          # Package execution wrapper
└── [various legacy binaries]     # Historical builds and tests
```

### Minimal Bun Wrapper Features

#### 1. **Simplified Architecture**
```bash
bun -> bun-minimal          # 25-line wrapper script
bunx -> bunx-minimal        # 4-line wrapper script  
```

#### 2. **Configuration-Driven Approach**
- **bunfig.toml**: Handles `backend=copyfile` and all optimizations automatically
- **grun integration**: Direct execution of working `buno` binary via glibc-runner
- **Minimal logic**: Only handles essential `bun run` directory reading issues

#### 3. **Package Management (via bunfig.toml)**
```bash
bun install    # bunfig.toml automatically applies backend=copyfile
bun add pkg    # bunfig.toml automatically applies backend=copyfile
```

#### 4. **Build Process Compatibility**
- Custom build.sh scripts handle compilation limitations
- `bun run build` executes project-specific build scripts
- No wrapper complexity needed - bunfig.toml + grun handles everything else

### Minimal Bun Wrapper Analysis
**File**: `~/.bun/bin/bun-minimal` 
**Size**: 25 lines (vs 200+ lines in previous version)
**Core Logic**:
- `bun run [script]` → Parse package.json and execute directly
- Everything else → `exec grun ~/.bun/bin/buno "$@"`
- All configuration handled by `~/bunfig.toml`

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
- **Primary Runtime**: Bun v1.2.20 (native ARM64 glibc via grun)
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
- **JavaScript Runtime**: Bun v1.2.20 with enhanced Termux wrapper  
- **Build Systems**: Custom solutions for compilation limitations
- **Package Installation**: Verified working with automatic conflict resolution

**Last Updated**: 2025-08-18
**Configuration Status**: Production Ready