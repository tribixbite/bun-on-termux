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
| `link`/`linkat` | Fall back to copy when hardlinks fail (Android f2fs) |

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
| `bun build --compile` | works | ~14KB output (embeds wrapper, not full runtime) |
| `bun -e '<code>'` | works | Inline eval |
| `bun repl` | works | Interactive REPL |
| `bunx <pkg>` | works | Package execution |
| `process.env.*` | works | Passed natively via C wrapper |
| `os.cpus()` | works | Shim spoofs `/proc/stat` |
| `Bun.serve()` | works | HTTP + WebSocket servers |
| `bun:sqlite` | works | Native SQLite binding |
| Workers | works | `new Worker()` threads |
| `Bun.spawn()` | works | Child process execution |
| `bun init` | works | Blank + React project templates |
| `bun create` | works | Vite, Astro templates via bunx |
| Third-party bun-compiled binaries | works | `BUN_BINARY_PATH=<binary> bun-termux` runs any standalone bun-compiled glibc binary (e.g. Claude Code 2.1.158). See [docs/BINARY-COMPATIBILITY.md](docs/BINARY-COMPATIBILITY.md#running-third-party-bun-compiled-binaries-bun_binary_path). |

## Known limitations

- **`bun build --compile` output**: Compiled binaries are ~14KB (embed the wrapper, not buno). They run on any Termux+glibc-runner device with buno + bun-shim.so installed, but are not standalone on non-Termux systems.
- **LD_PRELOAD scope**: Bun uses raw syscalls for JS-level file I/O (`fs.readFileSync`, `fs.statSync`), bypassing the shim. Shim interceptions only apply to glibc-internal operations (directory traversal, /proc reads, shebangs, hardlinks).
- **`fs.watch()`**: May not trigger reliably on all Android kernels due to inotify restrictions.
- **Platform detection**: Bun reports `linux-arm64` instead of `android-arm64`. Optional native binaries like `@rollup/rollup-android-arm64` must be installed via `npm install` if needed.
- **bash wrapper overhead**: Package.json parsing adds ~50-150ms startup overhead from fork/exec. Future v2 may port argument routing to C.

## Comparison with other Termux Bun projects

This project builds on techniques from two reference implementations. See [docs/COMPARISON.md](docs/COMPARISON.md) for full details.

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| **Repo** | [tribixbite/bun-on-termux](https://github.com/tribixbite/bun-on-termux) | [Happ1ness-dev/bun-termux](https://github.com/Happ1ness-dev/bun-termux) | [kaan-escober/bun-termux-loader](https://github.com/kaan-escober/bun-termux-loader) |
| **Approach** | Bash wrapper + C wrapper + shim | C wrapper + shim | Embedded binary + shim |
| **Bun binary** | External (`buno`) | External (`buno`) | Embedded (~92MB self-contained) |
| **Userland exec** | Yes | Yes | Yes |
| **`/proc/self/exe`** | Preserved | Preserved | Preserved |
| **Shim syscalls** | openat, stat, access, execve, link | openat, execve | dlopen |
| **`os.cpus()`** | Works (shim spoofs `/proc/stat`) | Works (shim spoofs `/proc/stat`) | N/A |
| **`fs.existsSync('/')`** | Works (stat interception) | Errors | Errors |
| **Hardlink fallback** | Auto copy via link/linkat shim | Manual `--backend=copyfile` | Manual `--backend=copyfile` |
| **Shebang translation** | Auto (`/usr/bin` -> `$PREFIX/bin`) | Auto (`/usr/bin` -> `$PREFIX/bin`) | None |
| **Bash wrapper** | Yes (arg routing, pkg.json, --cwd) | None | None |
| **`bun run <script>`** | Parses package.json | Passthrough to bun | N/A |
| **`bun install`** | Auto --cwd + --backend | Manual flags needed | N/A |
| **`bun init` / `bun create`** | Works (shim + wrapper) | Manual workarounds | N/A |
| **Compiled binaries** | Works (same device) | Works + replace_runtime.py | Works (self-contained) |
| **Test suite** | 80 tests, 18 categories | 8 tests | None |
| **Build tool** | Makefile (clang) | Makefile (clang) | Makefile + Python |

## Test suite

Run the comprehensive test suite (80 tests across 18 categories):

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
    bunx          <- bunx wrapper (delegates to bun x)
    env-preload.js <- legacy preload (kept as fallback)
  tests/
    run-tests.sh  <- test runner (80 tests)
    lib/          <- shared test helpers
    fixtures/     <- test fixture files
  config/
    bunfig.toml   <- global bun configuration
  helper_scripts/
    replace-runtime.py <- swap runtime in compiled binaries
  docs/
    ARCHITECTURE.md
    COMPARISON.md
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
- [Comparison](docs/COMPARISON.md) — feature comparison with other Termux Bun projects
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Installation](docs/INSTALLATION.md)
- [Binary Compatibility](docs/BINARY-COMPATIBILITY.md)
- [Termux Config](docs/TERMUX_CONFIG.md)

## License

MIT
