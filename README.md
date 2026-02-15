# Bun on Termux

Run [Bun](https://bun.sh) natively on Android via [Termux](https://termux.dev) using [glibc-runner](https://github.com/niclas-AE/glibc-runner).

**Current version**: Bun v1.3.9 (linux-aarch64 glibc) running through grun on Android ARM64.

## How it works

Bun is a glibc binary. Android uses bionic libc. The `glibc-runner` (`grun`) package provides a compatibility layer that invokes glibc's `ld-linux-aarch64.so.1` as a program loader to execute glibc binaries on bionic.

This creates two problems that this project solves:

1. **Environment variables are lost.** When `ld.so` is invoked as a program (rather than as the ELF interpreter via `PT_INTERP`), it zeroes the C `environ` pointer. The kernel-level environment in `/proc/self/environ` remains intact, but `process.env` in Bun/JS is empty.

2. **`std::env::current_dir()` fails.** Bun's internal `readDirInfo()` call fails when traversing `/data/data/` through glibc's dynamic linker, causing `CouldntReadCurrentDirectory` errors for `bun run`, config file reading, and other operations.

### Solution architecture

```
bun (wrapper) -> grun -> ld.so -> buno (real binary)
                           |
                     env-preload.js (restores process.env from /proc/self/environ)
```

The wrapper script (`bun`) handles:
- **CWD workaround**: Changes to a safe directory (`~/.bun/tmp`) before exec, resolves all file args to absolute paths
- **Env preload**: Passes `--preload env-preload.js` which reads `/proc/self/environ` and populates `process.env`
- **`bun run` parsing**: Intercepts `bun run <script>` to parse `package.json` scripts and route execution correctly
- **Global install backend**: Forces `--backend=copyfile` for global installs (Termux can't hardlink across filesystems)
- **Stderr filtering**: Suppresses non-fatal "Cannot read directory" noise from glibc path traversal

## Quick start

### Prerequisites

- **Termux** from F-Droid or GitHub (not Play Store)
- **termux-pacman** package manager (not apt/pkg)
- **glibc-runner**: `pacman -S glibc-runner`
- **ARM64 (aarch64)** device

### Install

```bash
git clone https://github.com/tribixbite/bun-on-termux.git
cd bun-on-termux
chmod +x setup.sh && ./setup.sh
```

Or manually:

```bash
mkdir -p ~/.bun/bin ~/.bun/tmp

# Copy the wrapper, preload script, and config
cp wrappers/bun-minimal ~/.bun/bin/bun
cp wrappers/env-preload.js ~/.bun/bin/
cp config/bunfig.toml ~/.bun/bin/

chmod +x ~/.bun/bin/bun

# Download and install the bun binary
BUN_VERSION="1.3.9"
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

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
| `bun script.js` | works | Direct file execution with env preload |
| `bun script.ts` | works | Native TypeScript, no transpile step |
| `bun run <script-name>` | works | Wrapper parses package.json |
| `bun run <file>` | works | Detects file path, routes to direct exec |
| `bun install` | works | Uses `copyfile` backend via bunfig.toml |
| `bun add <pkg>` | works | Local and global (auto `--backend=copyfile`) |
| `bun test` | works | Test runner with env preload |
| `bun build` | works | Bundler output to `./dist` |
| `bun -e '<code>'` | works | Inline eval with env preload |
| `bun repl` | works | Interactive REPL |
| `bun x <pkg>` (bunx) | partial | CouldntReadCurrentDirectory in some cases |
| `process.env.*` | works | Restored from `/proc/self/environ` via preload |
| Nested `bun run` scripts | works | Wrapper detects `"bun run ..."` in scripts |
| Shell scripts in package.json | works | Executed via `eval` in native Termux shell |

## Known limitations

- **`bunx` / `bun x`**: Can fail with `CouldntReadCurrentDirectory` when the executed package tries to read the working directory. Use `npx` as fallback.
- **`bun build --compile`**: Single-file compilation fails due to Android filesystem restrictions on the compiled output binary.
- **Hot reload / `--watch`**: Filesystem watching may not trigger reliably on all Android kernels.
- **grun startup overhead**: Each bun invocation pays ~30-50ms for the glibc dynamic linker setup. Still faster than Node.js overall (see benchmarks).
- **`+` operator in `-e` args**: The `+` character can get consumed in argument passing through the grun/ld.so chain. Use a file instead.
- **Stale install cache**: `bun add` may show EACCES warnings from prior cache entries with different permissions. The install itself still succeeds.
- **bunfig.toml preload chicken-and-egg**: The `[run] preload` setting in bunfig.toml cannot work standalone because bun needs env vars (HOME, BUN_INSTALL) to locate the config file in the first place. The `--preload` CLI flag in the wrapper is the actual fix.

## Benchmarks vs Node.js

Tested on Android ARM64 (Snapdragon), Termux, Bun v1.3.9 via grun, Node.js v24.9.0 native.

### Startup time (console.log + exit)

| Runtime | Avg (5 runs) | Notes |
|---------|-------------|-------|
| **bun** | **~85ms** | Includes grun + ld.so overhead |
| node | ~137ms | Native Termux binary |

Bun is **~38% faster** despite the glibc-runner indirection.

### Script execution (1M iteration loop)

| Runtime | Avg wall time (3 runs) | Computation only |
|---------|----------------------|------------------|
| **bun** | **~94ms** | ~6.6ms |
| node | ~137ms | ~6.1ms |

Bun is **~31% faster** in total wall time. Pure computation is roughly equal (V8 vs JSC), but bun's faster startup and lighter runtime give it the edge.

### TypeScript execution (native .ts file, 1M loop)

| Runtime | Avg wall time (3 runs) | Notes |
|---------|----------------------|-------|
| **bun** | **~93ms** | Native TS support, zero config |
| node | ~235ms | `--experimental-strip-types` |

Bun is **~60% faster** for TypeScript — no transpilation step needed.

### Package install (lodash, cold cache)

| Tool | Time | Notes |
|------|------|-------|
| **bun add** | **~645ms** | copyfile backend |
| npm install | ~1324ms | Default |

Bun is **~2x faster** for package installation.

## Technical deep dive

### The environment variable problem

When glibc-runner executes a binary, it runs:

```
exec /path/to/ld-linux-aarch64.so.1 /path/to/buno [args...]
```

This invokes `ld.so` as a standalone program rather than as the ELF interpreter (`PT_INTERP`). In this mode, glibc's runtime startup code zeroes the C `environ` pointer because it treats the actual binary as a "new" process payload. The result: `process.env` in JavaScript has 0 keys.

However, the Linux kernel maintains the original environment in `/proc/self/environ` as null-separated `KEY=VALUE\0` entries. The `env-preload.js` script reads this file and populates `process.env` before any user code runs:

```javascript
// env-preload.js (simplified)
if (Object.keys(process.env).length === 0) {
    const data = fs.readFileSync("/proc/self/environ", "utf8");
    for (const entry of data.split("\0")) {
        const idx = entry.indexOf("=");
        if (idx > 0) process.env[entry.substring(0, idx)] = entry.substring(idx + 1);
    }
}
```

### The CWD problem

Bun internally calls `std::env::current_dir()` (Rust) which resolves to `getcwd()` in glibc. When the process was launched via `ld.so`, the working directory traversal through `/data/data/com.termux/files/...` fails because glibc's directory reading code can't traverse Android's app-private filesystem hierarchy.

The wrapper solves this by:
1. Saving the original CWD at startup
2. Converting all relative file arguments to absolute paths
3. Changing to `~/.bun/tmp` (a safe, readable directory) before exec
4. Filtering the remaining non-fatal "Cannot read directory" stderr noise

### Wrapper execution flow

```
bun --version           -> passthrough: grun buno --version
bun script.ts           -> detect file -> absolute path -> _bun_js (grun + preload)
bun run dev             -> parse package.json -> route based on script content:
                             "bun run file.ts"  -> _bun_js with absolute path
                             "bun build ..."    -> _bun_js with preload
                             "echo hello"       -> eval in native Termux shell
bun install             -> _bun_cmd (grun, no preload needed)
bun add -g pkg          -> _bun_cmd + --backend=copyfile
bun test                -> _bun_js (needs env preload)
bun -e 'code'           -> _bun_js (needs env preload)
```

## File structure

```
~/.bun/
  bin/
    bun           <- wrapper script (this project)
    buno          <- real bun binary (official release)
    env-preload.js <- /proc/self/environ -> process.env bridge
    bunfig.toml   <- bun config (copyfile backend, preload, etc.)
  tmp/            <- safe CWD for grun execution
  install/
    cache/        <- package download cache
```

## Repository layout

```
bun-on-termux/
  wrappers/
    bun           <- main wrapper (copy of bun-minimal)
    bun-minimal   <- enhanced wrapper with env preload + safe CWD
    env-preload.js <- preload script for env var restoration
  config/
    bunfig.toml   <- global bun configuration for Termux
  docs/
    ARCHITECTURE.md
    INSTALLATION.md
    BINARY-COMPATIBILITY.md
    BINARY_PATCHING.md
    TROUBLESHOOTING.md
    TERMUX_CONFIG.md
    PACKAGE_MANAGER_MIGRATION.md
  setup.sh        <- automated installer
  test-bun-comprehensive.sh <- full test suite
```

## Upgrading bun

To upgrade to a new bun release:

```bash
# Backup current binary
cp ~/.bun/bin/buno ~/.bun/bin/buno-$(bun --version).bak

# Download new version
BUN_VERSION="1.3.9"  # change to desired version
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# Verify
bun --version
```

Use `bun-linux-aarch64.zip` (glibc variant), not the musl variant. The glibc variant is what works with glibc-runner.

## Docs

- [Architecture](docs/ARCHITECTURE.md) — how the wrapper, preload, and grun interact
- [Installation](docs/INSTALLATION.md) — step-by-step install guide
- [Binary Compatibility](docs/BINARY-COMPATIBILITY.md) — binary variants, SHA verification
- [Binary Patching](docs/BINARY_PATCHING.md) — grun --configure workflow
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common errors and fixes
- [Termux Config](docs/TERMUX_CONFIG.md) — pacman, glibc-runner, env vars
- [Package Manager Migration](docs/PACKAGE_MANAGER_MIGRATION.md) — apt to pacman

## License

MIT
