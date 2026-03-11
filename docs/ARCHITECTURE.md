# Bun on Termux Architecture

## Overview

Bun is a glibc-compiled binary. Android uses bionic libc. This project bridges the gap using a three-layer approach: a bash wrapper for argument routing, a C wrapper for userland exec, and an LD_PRELOAD shim for filesystem interception.

## Component diagram

```
User command
     |
     v
~/.bun/bin/bun          (bash wrapper script)
     |
     |- resolves relative paths to absolute
     |- parses package.json scripts
     |- injects --cwd/--backend for pkg management
     |
     v
~/.bun/bin/bun-termux   (C userland exec wrapper)
     |
     |- loads ld.so ELF segments into memory
     |- constructs stack with argc/argv/envp/auxv
     |- passes env vars natively (no preload needed)
     |- filters LD_PRELOAD/LD_LIBRARY_PATH
     |- sets BUN_FAKE_ROOT
     |
     v
ld-linux-aarch64.so.1   (glibc dynamic linker)
     |
     |- --preload bun-shim.so
     |- --library-path /usr/glibc/lib
     |- loads glibc shared libraries
     |
     v
bun-shim.so             (LD_PRELOAD interception)
     |
     |- intercepts openat: /proc/stat -> fake CPU info
     |- intercepts openat: /, /data, /storage -> safe dir
     |- intercepts stat/access: restricted paths -> synthetic
     |- intercepts execve: shebangs -> $PREFIX/bin translation
     |
     v
buno                    (real bun binary, v1.3.10)
     |
     v
User's JS/TS code       (full process.env, os.cpus(), etc.)
```

## Components

### 1. Bash wrapper (`~/.bun/bin/bun`)

**Source**: `wrappers/bun`

The bash wrapper is the user-facing entry point. It handles high-level argument routing that would be complex in C:

**Command routing**:
- `--version`, `--help`: Direct passthrough to bun-termux (no config needed)
- `bun <file>`: Detects file, resolves to absolute path, calls `_bun_js`
- `bun run <file>`: Same as above
- `bun run <script-name>`: Parses `package.json` to extract the script command:
  - `"bun run <file>"` -> routes back through `_bun_js`
  - `"bun <args>"` -> routes through `_bun_js`
  - Shell command -> `eval` in native Termux bash (preserves env)
- `test`, `eval`, `repl`, `build`, `-e`, `-p`, `--eval`: Routes to `_bun_js`
- `bun x` / bunx: Routes to `_bun_cmd`
- `install`, `add`, `remove`, `update`: Auto-injects `--cwd` and `--backend=copyfile`

**Execution modes**:
- `_bun_js()`: `exec bun-termux --config=bunfig.toml [args]`
- `_bun_cmd()`: Same, used for package management with additional flags

**Why bash**: Package.json parsing (grep+sed) and the variety of command routing patterns are natural in bash. The overhead is ~5ms on ARM64.

### 2. C wrapper (`bun-termux`)

**Source**: `src/bun-termux.c`

The C wrapper replaces `grun` (glibc-runner) as the execution backend. It performs userland exec:

1. **Loads ld.so**: Opens the glibc dynamic linker, reads ELF headers, maps all PT_LOAD segments into memory
2. **Constructs stack**: Builds a new stack with argc, argv, envp, and auxiliary vector (AT_PHDR, AT_ENTRY, AT_RANDOM, etc.)
3. **Passes env vars**: Environment variables are placed directly on the new stack — no preload script needed
4. **Filters env**: Removes `LD_PRELOAD` and `LD_LIBRARY_PATH` from the environment (uses `--library-path` flag to ld.so instead)
5. **Sets BUN_FAKE_ROOT**: Tells the shim where the safe directory is
6. **Jumps to entry**: Blocks signals, switches stack pointer, and branches to ld.so's entry point via inline assembly

**Why userland exec**: Standard `exec()` would use bionic's dynamic linker. By manually loading ld.so and constructing the stack, we have full control over the glibc environment without needing `grun`.

### 3. LD_PRELOAD shim (`bun-shim.so`)

**Source**: `src/shim.c`

The shim is preloaded by ld.so (via `--preload` flag) and intercepts filesystem syscalls:

| Intercepted | Purpose |
|-------------|---------|
| `openat`/`openat64`/`open`/`open64` | Redirect `/proc/stat` reads to a fake file with CPU info (fixes `os.cpus()`). Redirect `O_DIRECTORY` opens of restricted paths (`/`, `/data`, `/storage`) to `BUN_FAKE_ROOT` (fixes `CouldntReadCurrentDirectory`). |
| `stat`/`lstat`/`fstatat`/`__xstat`/`__lxstat` | Synthesize directory stat results for restricted paths (fixes `fs.existsSync('/')`, `fs.statSync('/')`) |
| `access`/`faccessat` | Intercept permission checks on restricted paths (fixes `fs.accessSync`) |
| `execve` | Parse shebangs and translate FHS paths (`/usr/bin/env`, `/bin/sh`) to `$PREFIX/bin` equivalents |
| `link`/`linkat` | Fall back to file copy when hardlinks fail with EACCES/EPERM (Android f2fs blocks hardlinks; fixes `bun install`, `bun init`, `bun create`) |

**Fake /proc/stat**: Android restricts access to `/proc/stat`. The shim generates a synthetic file with per-CPU lines based on `sysconf(_SC_NPROCESSORS_ONLN)`. Uses `memfd_create` (kernel >= 3.17) with temp file fallback.

**Directory redirection**: Bun's internal `readDirInfo()` traverses the CWD's parent hierarchy. On Android, reading `/data/data/` fails with EACCES. The shim redirects these to `BUN_FAKE_ROOT` (typically `~/.bun/tmp/fake-root`).

**Shebang translation**: When bun spawns a child process with a shebang like `#!/usr/bin/env node`, the shim translates this to `$PREFIX/bin/env node` before calling the real `execve`.

### 4. Bun binary (`buno`)

- **File**: `~/.bun/bin/buno`
- **Variant**: `bun-linux-aarch64` (glibc, not musl)
- **Version**: v1.3.10
- **Size**: ~100MB
- **Source**: Official [oven-sh/bun](https://github.com/oven-sh/bun) GitHub releases

Named `buno` ("bun original") so the wrapper script can use the standard `bun` command name.

### 5. Configuration (`bunfig.toml`)

**Location**: `~/.bun/bin/bunfig.toml` (referenced via `--config=` flag)

Key settings:
- `[install] exact = true` — exact version pinning
- `[run] shell = "system"` — use Termux's native shell

Note: `backend = "copyfile"` is a CLI-only flag (`--backend=copyfile`), not a valid bunfig.toml key. The bash wrapper injects it for package management commands. The shim's link/linkat interception also provides automatic fallback.

## Execution flows

### `bun script.ts`

```
1. Wrapper: _abs_path("script.ts") -> /full/path/script.ts
2. Wrapper: file exists? yes -> shift, _bun_js "/full/path/script.ts"
3. _bun_js: exec bun-termux --config=bunfig.toml /full/path/script.ts
4. bun-termux: load ld.so, construct stack with 98+ env vars
5. ld.so: preload bun-shim.so, load glibc, exec buno
6. buno: executes /full/path/script.ts with full environment
```

### `bun install`

```
1. Wrapper: $1="install" -> package management
2. Wrapper: inject --backend=copyfile --cwd /original/cwd
3. _bun_cmd: exec bun-termux --config=bunfig.toml install --backend=copyfile --cwd /original/cwd
4. bun-termux: userland exec with env vars
5. buno: resolves, downloads, extracts packages using copyfile
```

### `bun build --compile`

```
1. Wrapper: $1="build" -> _bun_js
2. _bun_js: exec bun-termux --config=bunfig.toml build --compile ...
3. bun-termux: userland exec
4. Shim: openat("/") redirected to fake-root (fixes dir traversal)
5. Shim: /proc/stat spoofed (os.cpus() works)
6. buno: compiles bundle -> produces working aarch64 binary
```

## Performance

| Layer | Overhead | Notes |
|-------|----------|-------|
| Wrapper (bash) | ~5ms | Argument parsing, path resolution |
| bun-termux (C) | ~5ms | ELF loading, stack construction |
| ld.so | ~20ms | Dynamic library loading |
| bun-shim.so | <1ms | Constructor + syscall interception |
| **Total overhead** | **~30ms** | Down from ~37ms with grun |

## Security notes

- Runs within Termux's sandbox (no root required)
- The shim only intercepts specific paths — all other syscalls pass through
- No binary patching or ELF modification performed
- `BUN_FAKE_ROOT` is a user-owned temp directory
- Environment variables passed natively (no `/proc/self/environ` parsing)

## Related projects

This project's C wrapper and shim are adapted from two reference implementations. See [COMPARISON.md](COMPARISON.md) for a detailed feature comparison.

- [Happ1ness-dev/bun-termux](https://github.com/Happ1ness-dev/bun-termux) — minimal C wrapper + shim (openat, execve)
- [kaan-escober/bun-termux-loader](https://github.com/kaan-escober/bun-termux-loader) — self-contained embedded binary approach

## Legacy: env-preload.js

The `env-preload.js` preload script is kept in the repo as a fallback for systems without the C wrapper. It reads `/proc/self/environ` and populates `process.env` when env vars are missing (the `grun`-only scenario). With the C wrapper, this is unnecessary — env vars are passed natively via the constructed stack.
