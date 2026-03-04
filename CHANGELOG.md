# Changelog

## 2026-03-04

### Fixed
- **`bun install` / `bun add` CWD mismatch**: The wrapper's `cd ~/.bun/tmp` caused bun to look for `package.json` in the wrong directory. Now auto-injects `--cwd "$_ORIG_CWD"` for all package management commands (install, add, remove, update). No more manual `--cwd` workaround needed.
- **Hardlink EACCES on all installs**: Previously only global installs got `--backend=copyfile`. Now all package management commands get it automatically, since Android f2fs blocks hardlinks regardless of scope.
- **`node_modules/.bin` not in PATH**: Shell scripts in `package.json` couldn't find locally-installed binaries. Wrapper now adds `node_modules/.bin` to PATH before executing shell scripts (matching npm/bun native behavior).

## 2025-02-15

### Upgraded
- Bun binary from v1.2.20 to v1.3.9 (`bun-linux-aarch64` glibc variant)
- SHA256 verified against official GitHub release

### Fixed
- **Environment variables**: Solved the root cause — glibc's `ld.so` zeroes C `environ` when invoked as a program loader. Added `env-preload.js` that reads `/proc/self/environ` and populates `process.env` via `--preload` flag
- **`bun run` script handling**: Fixed `shift 2` (was `shift 1`, leaving script name as extra arg), added `eval` for shell expansion in package.json scripts, proper routing for nested `bun run` calls
- **CouldntReadCurrentDirectory**: Wrapper now `cd`s to `~/.bun/tmp` before exec and converts all args to absolute paths
- **`--config` syntax**: Changed from `--config <path>` (consumed next arg) to `--config=<path>`
- **stderr noise**: Added `2> >(grep -v "Cannot read directory" >&2)` to filter non-fatal glibc path traversal warnings

### Added
- `env-preload.js` — preload script that bridges `/proc/self/environ` to `process.env`
- `bunfig.toml` — global config with `backend=copyfile`, preload, and Termux-optimized defaults
- Rewritten `bun-minimal` wrapper with safe CWD, absolute path resolution, command routing
- Comprehensive README with technical explanation, benchmarks, and limitations

### Architecture
- Confirmed binary is `bun-linux-aarch64` (glibc), not musl as previously assumed
- Documented why patchelf approach fails (libc.so linker script, LD_PRELOAD bionic/glibc conflict)
- Documented bunfig.toml preload chicken-and-egg problem (bun needs env vars to find config)

## 2025-08 (Initial)

### Added
- Initial setup with glibc-runner integration
- Basic wrapper script for `bun run` and package management
- bunx wrapper for package execution
- Test suite (`test-bun-comprehensive.sh`)
- Documentation for architecture, installation, troubleshooting, binary patching
