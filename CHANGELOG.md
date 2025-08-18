# Changelog

All notable changes to Bun on Termux will be documented in this file.

## [1.1.0] - 2025-08-18

### Added
- **Global Install Support**: Automatic `--backend=copyfile` for `bun i -g` commands
- **Comprehensive Test Suite**: Complete testing of all Bun commands and edge cases
- **Architecture Documentation**: Detailed technical documentation of the implementation
- **Enhanced Wrapper**: Improved wrapper logic for better command handling
- **uwu Integration**: Working AI command generation with API key support

### Fixed
- **Global Package Installation**: Fixed permission errors with global installs
- **Directory Reading**: Improved handling of Android filesystem restrictions
- **Environment Variables**: Documented grun limitations and provided workarounds
- **Package.json Scripts**: Reliable execution through wrapper parsing
- **Binary Compatibility**: Using stable `buno` binary instead of segfaulting alternatives

### Technical Details
- **Root Cause Analysis**: Identified that global installs don't read local `bunfig.toml`
- **glibc-runner Integration**: Better understanding of environment variable isolation
- **Wrapper Enhancement**: Added automatic backend detection and injection
- **Testing Coverage**: 40+ test cases covering all major Bun functionality

### Known Limitations
- Environment variables don't pass through glibc-runner (design limitation)
- Some build compilation features restricted on ARM64 Android
- Hot reload and file watching may have limitations

## [1.0.0] - 2025-08-18

### Added
- **Initial Release**: Working Bun implementation on Termux Android
- **Core Features**:
  - Direct file execution (`bun script.js`, `bun script.ts`)
  - Package management (`bun install`, `bun add`, `bun remove`)
  - Build system (`bun build`)
  - Package.json script execution (`bun run`)
- **Wrapper System**: Custom wrapper handling Android-specific issues
- **Configuration**: Global `bunfig.toml` with Termux optimizations
- **Documentation**: Setup guide, troubleshooting, and usage examples

### Technical Implementation
- **glibc-runner Integration**: Using glibc v2.0-3 from upds branch
- **Binary Management**: Working ARM64 musl binary (`buno`)
- **Filesystem Workarounds**: Handling directory reading restrictions
- **Installation System**: Automated setup script with dependency checking

### Repository Structure
- Complete project organization with docs, tests, and binaries
- MIT license and contribution guidelines
- Comprehensive README with installation and usage instructions

---

## Development Notes

### Version Numbering
- **Major**: Significant architecture changes or new core features
- **Minor**: New functionality, improvements, or important fixes
- **Patch**: Bug fixes, documentation updates, minor improvements

### Testing
Each release is validated with the comprehensive test suite covering:
- All Bun commands and flags
- Package management scenarios
- Build and compilation features
- Error handling and edge cases
- Performance and compatibility checks

### Contributing
See CONTRIBUTING.md for development setup and contribution guidelines.