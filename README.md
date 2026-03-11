# Bun on Termux

Run [Bun](https://bun.sh) natively on Android via [Termux](https://termux.dev) using a C userland exec wrapper + LD_PRELOAD shim.

**Current version**: Bun v1.3.10 (linux-aarch64 glibc) on Android ARM64.

## How it works

Bun is a glibc binary. Android uses bionic libc. This project provides:

1. **`bun-termux` (C wrapper)** — loads glibc's `ld-linux-aarch64.so.1` via userland exec, passing environment variables natively through the constructed stack
2. **`bun-shim.so` (LD_PRELOAD shim)** — intercepts filesystem syscalls to work around Android's restricted directory access
3. **`bun` (bash wrapper)** — handles argument routing, package.json script parsing, and `--cwd`/`--backend` injection

### Architecture

```
bun (bash wrapper) -> bun-termux (C) -> ld.so -> bun-shim.so -> buno (real binary)
     |                    |                          |
     |                    |                    intercepts: openat, stat,
     |                    |                    access, execve, /proc/stat
     |                    |
     |               userland exec:
     |               - maps ld.so ELF segments
     |               - constructs stack (argv/envp/auxv)
     |               - passes env vars natively
     |               - filters LD_PRELOAD/LD_LIBRARY_PATH
     |
     handles: argument parsing, package.json scripts,
     --cwd injection, --backend=copyfile for pkg mgmt
```

### What the shim intercepts

| Syscall | Purpose |
|---------|---------|
| `openat`/`openat64`/`open`/`open64` | Redirect `/proc/stat` (fake CPU info for `os.cpus()`), redirect `O_DIRECTORY` reads of `/`, `/data`, `/storage` to safe dir |
| `stat`/`lstat`/`fstatat` | Synthesize directory stats for restricted paths (`fs.existsSync`, `fs.statSync`) |
| `access`/`faccessat` | Intercept permission checks on restricted paths |
| `execve` | Parse shebangs, translate `/usr/bin` -> `$PREFIX/bin` |

## Quick start

### Prerequisites

- **Termux** from F-Droid or GitHub (not Play Store)
- **termux-pacman** package manager (not apt/pkg)
- **glibc-runner**: `pacman -S glibc-runner`
- **clang**: `pkg install clang` (for building C components)
- **ARM64 (aarch64)** device

### Install

```bash
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux
make install
chmod +x setup.sh && ./setup.sh
```

Or manually:

```bash
mkdir -p ~/.bun/{bin,lib,tmp/fake-root}

# Build and install C components
make all
cp bun-termux ~/.bun/bin/
cp bun-shim.so ~/.bun/lib/

# Copy wrapper and config
cp wrappers/bun ~/.bun/bin/bun-minimal
ln -sf bun-minimal ~/.bun/bin/bun
cp config/bunfig.toml ~/.bun/bin/

# Download bun binary
BUN_VERSION="1.3.10"
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno ~/.bun/bin/bun-termux

# Add to PATH
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
bun --version
```

## What works

| Feature | Status | Notes |
|---------|--------|-------|
| `bun --version` | works | Passthrough to binary |
| `bun script.ts` | works | Native TypeScript execution |
| `bun script.js` | works | Direct file execution |
| `bun run <script>` | works | Wrapper parses package.json |
| `bun install` | works | `copyfile` backend, auto `--cwd` |
| `bun add <pkg>` | works | Local and global |
| `bun test` | works | Test runner with fixture discovery |
| `bun build` | works | Bundler with all flags |
| `bun build --compile` | works | Produces working binaries |
| `bun -e '<code>'` | works | Inline eval |
| `bun repl` | works | Interactive REPL |
| `bunx <pkg>` | works | Package execution |
| `process.env.*` | works | Passed natively via C wrapper |
| `os.cpus()` | works | Shim spoofs `/proc/stat` |
| `Bun.serve()` | works | HTTP + WebSocket servers |
| `bun:sqlite` | works | Native SQLite binding |
| Workers | works | `new Worker()` threads |
| `Bun.spawn()` | works | Child process execution |

## Known limitations

- **`bun build --compile` output**: Compiled binaries work on the same device but still depend on Termux glibc + buno. Not truly standalone.
- **`fs.watch()`**: May not trigger reliably on all Android kernels due to inotify restrictions.
- **Platform detection**: Bun reports `linux-arm64` instead of `android-arm64`. Optional native binaries like `@rollup/rollup-android-arm64` must be installed via `npm install` if needed.
- **bash wrapper overhead**: Package.json parsing adds ~50-150ms startup overhead from fork/exec. Future v2 may port argument routing to C.

## Test suite

Run the comprehensive test suite (76 tests across 18 categories):

```bash
bash tests/run-tests.sh
```

Filter by category or pattern:

```bash
bash tests/run-tests.sh --category K        # Bun APIs only
bash tests/run-tests.sh --filter "sqlite"   # Pattern match
```

Categories: A=CLI, B=FileExec, C=Eval, D=REPL, E=TestRunner, F=Build, G=PkgMgmt, H=Scripts, I=Bunx, J=Create, K=BunAPIs, L=EnvVars, M=LowLevel, N=DevServer, O=Network, P=Workers, Q=FFI, R=Stress

## File structure

```
~/.bun/
  bin/
    bun           -> bun-minimal (symlink)
    bun-minimal   <- bash wrapper script
    bun-termux    <- C userland exec wrapper
    buno          <- real bun binary (official release)
    bunfig.toml   <- bun config
  lib/
    bun-shim.so   <- LD_PRELOAD interception shim
  tmp/
    fake-root/    <- safe directory for shim redirects
  install/
    cache/        <- package download cache
```

## Repository layout

```
bun-on-termux/
  src/
    bun-termux.c  <- C wrapper (userland exec)
    shim.c        <- LD_PRELOAD shim
  wrappers/
    bun           <- main wrapper script
    bunx          <- bunx wrapper
    env-preload.js <- legacy preload (kept as fallback)
  tests/
    run-tests.sh  <- test runner (76 tests)
    lib/          <- shared test helpers
    fixtures/     <- test fixture files
  config/
    bunfig.toml   <- global bun configuration
  docs/
    ARCHITECTURE.md
    TROUBLESHOOTING.md
    ...
  Makefile        <- build system
  setup.sh        <- automated installer
```

## Upgrading bun

```bash
# Download specific version
bash scripts/download-official-bun.sh 1.3.10

# Or manually
cp ~/.bun/bin/buno ~/.bun/bin/buno.$(bun --version).bak
BUN_VERSION="1.3.10"
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno
bun --version
```

Use `bun-linux-aarch64.zip` (glibc variant), not musl.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Installation](docs/INSTALLATION.md)
- [Binary Compatibility](docs/BINARY-COMPATIBILITY.md)

## License

MIT
