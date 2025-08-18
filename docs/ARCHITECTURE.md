# Bun on Termux Architecture

## Overview

This document explains the technical architecture of how Bun works on Termux Android.

## Core Components

### 1. glibc-runner (grun)
- **Purpose**: Compatibility layer for running glibc binaries on Android bionic
- **Version**: v2.0-3 from upds branch
- **Location**: `/data/data/com.termux/files/usr/bin/grun`
- **Function**: Patches binary ELF headers and sets up glibc environment

### 2. Bun Binary (buno)
- **Type**: ARM64 musl-based binary 
- **Location**: `~/.bun/bin/buno`
- **Compatibility**: Works with glibc-runner for Android execution

### 3. Wrapper Script
- **Purpose**: Handles Termux-specific issues and compatibility
- **Location**: `~/.bun/bin/bun`
- **Key Functions**:
  - Directory reading workarounds
  - Global install backend enforcement
  - Package.json script parsing

### 4. Global Configuration
- **File**: `~/bunfig.toml`
- **Purpose**: Default settings for all Bun operations
- **Key Settings**: `backend=copyfile` for Termux compatibility

## Execution Flow

### Direct File Execution
```
bun script.js → wrapper → grun → buno → script execution
```
- ✅ Works reliably
- ✅ No directory reading required
- ✅ Fast execution path

### Package.json Scripts (`bun run`)
```
bun run dev → wrapper detects → parses package.json → direct execution
```
- ⚠️ Requires wrapper intervention
- 🔧 Bypasses Bun's `configureEnvForRun()` function
- ✅ Works through script parsing workaround

### Package Management
```
# Local installs
bun install → wrapper → grun → buno + bunfig.toml backend

# Global installs  
bun i -g → wrapper → grun → buno + --backend=copyfile (forced)
```
- ✅ Local installs use bunfig.toml
- ✅ Global installs get forced copyfile backend

## Technical Challenges

### 1. Directory Reading (Core Issue)
**Problem**: Android filesystem restrictions prevent `readDirInfo()` calls
**Affected**: `bun run` commands, config file reading
**Solution**: Wrapper-based workarounds and direct execution

### 2. Environment Variable Isolation
**Problem**: glibc-runner doesn't pass environment variables
**Root Cause**: `exec ld.so $@` doesn't preserve parent environment
**Workaround**: Config files, hardcoded values, or wrapper scripts

### 3. Global Install Backend
**Problem**: Global installs ignore local bunfig.toml
**Reason**: By design - global operations are project-independent  
**Solution**: Wrapper automatically adds `--backend=copyfile`

### 4. Binary Compatibility
**Problem**: Some Bun binaries segfault on Android
**Solution**: Use working `buno` binary instead of standard builds

## Code Paths

### Successful Execution Path
1. **Direct execution**: `maybeOpenWithBunJS()` → works
2. **Package management**: Uses copyfile backend → works  
3. **Building/bundling**: Standard Bun operations → works

### Problematic Path (Fixed)
1. **Script running**: `RunCommand.exec()` → `configureEnvForRun()` → `readDirInfo()` → FAILS
2. **Workaround**: Wrapper parses package.json and uses direct execution

## Performance Characteristics

### Memory Usage
- **grun overhead**: ~5-10MB additional memory
- **Wrapper overhead**: Negligible (<1MB)
- **Binary size**: ~90MB for full Bun installation

### Execution Speed
- **Direct execution**: Near-native performance
- **Package installs**: Slower due to copyfile vs hardlink
- **Script parsing**: Minimal overhead from wrapper

### Network Performance
- **Registry access**: Standard HTTP performance
- **Package downloads**: Limited by mobile network
- **Parallel installs**: Works with `--concurrent` flags

## Security Considerations

### Filesystem Access
- **Permissions**: Runs within Termux sandbox
- **Path access**: Limited to Termux directories
- **Root access**: Not required or used

### Binary Verification
- **ELF patching**: grun modifies binary headers
- **Library loading**: Uses controlled glibc environment
- **Execution**: No elevated privileges needed

## Debugging Architecture

### Logging Levels
```bash
# Basic wrapper debug
WRAPPER_DEBUG=1 bun command

# grun strace debugging  
grun --debug 3 ~/.bun/bin/buno command

# Comprehensive testing
./test-bun-comprehensive.sh
```

### Common Debug Points
1. **Wrapper logic**: Check argument parsing and flow control
2. **grun execution**: Monitor ELF patching and library loading
3. **Directory access**: Test filesystem permission issues
4. **Environment passing**: Verify variable inheritance

## Future Improvements

### Potential Optimizations
1. **Direct glibc integration**: Eliminate grun overhead
2. **Source patches**: Fix directory reading in Bun source
3. **Native Android build**: ARM64 Android-specific Bun binary
4. **Environment bridging**: Better variable passing through grun

### Limitations to Address
1. **Build compilation**: `bun build --compile` restrictions
2. **Hot reload**: Filesystem watching limitations  
3. **Test runner**: Some test features may be limited
4. **Development server**: Port binding and network access

## Integration Points

### Package Managers
- **npm compatibility**: Full package.json support
- **yarn compatibility**: Most features work
- **pnpm integration**: Limited compatibility

### Development Tools
- **TypeScript**: Full support through Bun runtime
- **Bundling**: Works with copyfile backend
- **Testing**: Basic test runner functionality
- **Linting**: External tools work normally

### System Integration
- **Shell integration**: Works through Termux bash
- **File associations**: Can be configured
- **PATH integration**: Automatic through setup
- **Process management**: Standard Unix signals