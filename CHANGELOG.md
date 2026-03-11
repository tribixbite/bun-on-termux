# Changelog

## 2026-03-11

### Major Architecture: C Wrapper + LD_PRELOAD Shim

Replaced `grun` (glibc-runner) with a custom C userland exec wrapper + LD_PRELOAD shim.
This eliminates the env-preload.js hack, the safe-CWD hack, and the --backend=copyfile requirement.

### Added
- **`bun-termux` (C wrapper)**: Loads glibc's `ld-linux-aarch64.so.1` via userland exec, passes env vars natively through the constructed stack. Replaces `grun` entirely.
- **`bun-shim.so` (LD_PRELOAD shim)**: Intercepts filesystem syscalls:
  - `openat`/`open`: Redirect `/proc/stat` (fake CPU info for `os.cpus()`), redirect restricted directory reads to safe dir
  - `stat`/`lstat`/`fstatat`: Synthesize directory stats for restricted paths
  - `access`/`faccessat`: Intercept permission checks on restricted paths
  - `execve`: Parse shebangs, translate `/usr/bin` -> `$PREFIX/bin`
  - `link`/`linkat`: Fall back to file copy when hardlinks fail (Android f2fs)
- **Modular test suite**: 80 tests across 18 categories (A-R), replacing old monolithic script
- **Create template tests**: `bun init`, `bun init --react`, `bunx create-vite`, `bunx create-astro`
- **Makefile**: Build system for C components (`make all`, `make install`)

### Upgraded
- Bun binary from v1.3.9 to **v1.3.10** (`bun-linux-aarch64` glibc variant)

### Removed
- `env-preload.js` as default preload (C wrapper passes env vars natively)
- Safe CWD hack (`cd ~/.bun/tmp`) — shim handles directory access
- `test-bun-comprehensive.sh` (replaced by `tests/run-tests.sh`)

### Fixed
- **`bun init` / `bun create`**: `--config=` flag was breaking `bun init` (bun misinterprets command name as folder). Wrapper now skips `--config` for init/create.
- **`bunfig.toml` backend key**: Discovered `backend = "copyfile"` is NOT a valid bunfig key (CLI-only flag). Removed from config. Shim's link/linkat interception makes it unnecessary.
- **`bun build --compile`**: Now produces working binaries (shim handles directory traversal)
- **`os.cpus()`**: Now returns proper CPU info (shim spoofs `/proc/stat`)

## 2026-03-04

### Fixed
- **`bun install` CWD mismatch**: Auto-injects `--cwd "$_ORIG_CWD"` for all package management commands
- **Hardlink EACCES on all installs**: All package management commands get `--backend=copyfile` automatically
- **`node_modules/.bin` not in PATH**: Wrapper adds to PATH before shell scripts

## 2025-02-15

### Upgraded
- Bun binary from v1.2.20 to v1.3.9 (`bun-linux-aarch64` glibc variant)

### Fixed
- **Environment variables**: Added `env-preload.js` to read `/proc/self/environ` (glibc's ld.so zeroes C environ)
- **`bun run` script handling**: Fixed shift logic, added eval for shell expansion
- **CouldntReadCurrentDirectory**: Wrapper cd's to `~/.bun/tmp` before exec (later replaced by shim)

### Added
- `env-preload.js`, `bunfig.toml`, rewritten wrapper with safe CWD

## 2025-08 (Initial)

### Added
- Initial setup with glibc-runner (grun) integration
- Basic wrapper script, bunx wrapper, test suite
- Documentation for architecture, installation, troubleshooting
