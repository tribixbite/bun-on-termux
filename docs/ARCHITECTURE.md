# Bun on Termux Architecture

## Overview

Bun is a glibc-compiled binary. Android uses bionic libc. To bridge this gap, we use `glibc-runner` (`grun`) which invokes glibc's dynamic linker (`ld-linux-aarch64.so.1`) as a program loader. A bash wrapper script and a JS preload script handle the side effects of this approach.

## Component diagram

```
User command
     |
     v
~/.bun/bin/bun          (bash wrapper script)
     |
     |- saves original CWD
     |- resolves relative paths to absolute
     |- cd ~/.bun/tmp (safe CWD)
     |
     v
grun                    (glibc-runner: exec ld.so binary)
     |
     v
ld-linux-aarch64.so.1   (glibc dynamic linker)
     |
     |- zeroes C environ pointer (side effect)
     |- loads glibc shared libraries
     |
     v
buno                    (real bun binary, v1.3.9)
     |
     |- --preload env-preload.js
     |     |
     |     |- reads /proc/self/environ
     |     |- populates process.env
     |
     v
User's JS/TS code       (full process.env available)
```

## Components

### 1. Wrapper script (`~/.bun/bin/bun`)

**Source**: `wrappers/bun-minimal` (137 lines)

The wrapper is the entry point for all `bun` commands. It handles:

**CWD management**: Saves original CWD, converts all file-like arguments to absolute paths, then `cd`s to `~/.bun/tmp` before exec. This avoids the `CouldntReadCurrentDirectory` error caused by glibc's `getcwd()` failing to traverse `/data/data/` paths.

**Command routing**:
- `--version`, `--help`: Direct passthrough to buno (no preload needed)
- `bun run <file>`: Detects file, shifts args, calls `_bun_js` with absolute path
- `bun run <script-name>`: Parses `package.json` to extract the script command, then:
  - If script is `bun run <file>` or `bun <args>`: routes back through `_bun_js`
  - If script is a shell command: `eval`s in native Termux shell (preserves env vars)
- `bun <file>`: Detects file argument, routes to `_bun_js`
- `test`, `eval`, `repl`, `build`, `-e`: Routes to `_bun_js` (needs env preload)
- `bun x` / bunx: Routes to `_bun_cmd` (no preload, uses grun only)
- `install`, `add`, `remove`, `update`: Routes to `_bun_cmd`, auto-adds `--backend=copyfile` for global installs

**Execution modes**:
- `_bun_js()`: `exec grun buno --preload env-preload.js --config=bunfig.toml [args]` — for JS/TS execution
- `_bun_cmd()`: `exec grun buno --config=bunfig.toml [args]` — for non-JS commands (install, etc.)

**Stderr filtering**: Both modes pipe stderr through `grep -v "Cannot read directory"` to suppress non-fatal noise from glibc's directory traversal attempts.

### 2. Environment preload (`env-preload.js`)

**Problem**: When `ld.so` is invoked as a program loader (not as `PT_INTERP`), glibc's `__libc_start_main` zeroes the C `environ` pointer. The kernel's `/proc/self/environ` still has all 100+ environment variables, but `process.env` in JS shows 0 keys.

**Solution**: A preload script runs before user code:

```javascript
if (Object.keys(process.env).length === 0) {
    const data = fs.readFileSync("/proc/self/environ", "utf8");
    for (const entry of data.split("\0")) {
        const idx = entry.indexOf("=");
        if (idx > 0) {
            process.env[entry.substring(0, idx)] = entry.substring(idx + 1);
        }
    }
}
```

The guard `Object.keys(process.env).length === 0` ensures this only runs when env vars are actually missing (i.e., via grun). If bun ever runs natively without grun, the preload is a no-op.

### 3. Bun binary (`buno`)

- **File**: `~/.bun/bin/buno`
- **Variant**: `bun-linux-aarch64` (glibc, not musl)
- **Version**: v1.3.9
- **Size**: ~100MB
- **Source**: Official [oven-sh/bun](https://github.com/oven-sh/bun) GitHub releases

Named `buno` ("bun original") so the wrapper script can use the standard `bun` command name.

### 4. Configuration (`bunfig.toml`)

**Location**: `~/.bun/bin/bunfig.toml` (referenced via `--config=` flag)

Key settings:
- `[install] backend = "copyfile"` — Termux can't hardlink across filesystems; copyfile works everywhere
- `[install] auto = false` — disable lifecycle scripts that may fail on Android
- `[run] preload = ["/path/to/env-preload.js"]` — backup preload config (wrapper's `--preload` flag is the primary mechanism)
- `[run] shell = "system"` — use Termux's native shell for script execution

Note: The bunfig.toml `[run] preload` setting has a chicken-and-egg problem. Bun needs `HOME` and `BUN_INSTALL` env vars to locate the config file, but those vars are only available after the preload runs. The `--preload` CLI flag in the wrapper bypasses this.

### 5. glibc-runner (`grun`)

- **Package**: `glibc-runner` via `pacman -S glibc-runner`
- **Location**: `/data/data/com.termux/files/usr/bin/grun`
- **Glibc root**: `/data/data/com.termux/files/usr/glibc/`
- **Dynamic linker**: `/data/data/com.termux/files/usr/glibc/lib/ld-linux-aarch64.so.1`

Core execution (from `glibc-runner.sh` line 276):
```bash
exec $(_glibc-runner_debug) ld.so $@
```

This invokes the glibc dynamic linker as a program, passing the target binary as an argument. The linker loads all required glibc shared libraries and transfers control to the binary.

## Execution flows

### `bun script.ts`

```
1. Wrapper: _ORIG_CWD=$(pwd), _abs_path("script.ts") -> /full/path/script.ts
2. Wrapper: file exists? yes -> shift, _bun_js "/full/path/script.ts"
3. _bun_js: cd ~/.bun/tmp
4. _bun_js: exec grun buno --preload env-preload.js --config=bunfig.toml /full/path/script.ts
5. grun: exec ld.so buno --preload env-preload.js --config=bunfig.toml /full/path/script.ts
6. buno: loads env-preload.js -> reads /proc/self/environ -> populates process.env
7. buno: executes /full/path/script.ts with full environment
```

### `bun run dev` (package.json script: `"dev": "bun run src/index.ts"`)

```
1. Wrapper: $1="run", $2="dev" -> not a file
2. Wrapper: finds package.json -> extracts "bun run src/index.ts"
3. Wrapper: script starts with "bun run " -> extract "src/index.ts"
4. Wrapper: _abs_path("src/index.ts") -> /full/path/src/index.ts
5. Wrapper: shift 2, _bun_js "/full/path/src/index.ts"
6. (continues as direct file execution above)
```

### `bun run dev` (package.json script: `"dev": "echo hello && node server.js"`)

```
1. Wrapper: $1="run", $2="dev" -> not a file
2. Wrapper: finds package.json -> extracts "echo hello && node server.js"
3. Wrapper: script doesn't start with "bun" -> shell command
4. Wrapper: cd back to original CWD
5. Wrapper: eval "echo hello && node server.js"
6. Executes in native Termux bash (full env vars available natively)
```

### `bun install`

```
1. Wrapper: $1="install" -> package management
2. Wrapper: no -g flag -> _bun_cmd "install"
3. _bun_cmd: cd ~/.bun/tmp
4. _bun_cmd: exec grun buno --config=bunfig.toml install
5. buno: reads bunfig.toml -> backend=copyfile
6. buno: resolves, downloads, extracts packages using copyfile
```

## Why not patchelf?

We investigated using `patchelf` to modify the bun binary's ELF headers to embed the glibc interpreter path directly, which would eliminate the grun wrapper entirely. This failed for two reasons:

1. **libc.so is a linker script**: glibc's `libc.so` in Termux is a GNU ld text script (not an ELF binary). It directs the linker to load `libc.so.6`. When patchelf'd binaries try to load `libc.so` directly via `DT_NEEDED`, they get "invalid ELF header" errors.

2. **LD_PRELOAD conflict**: Termux's `libtermux-exec-ld-preload.so` is a bionic library. When a patchelf'd binary runs with glibc's dynamic linker, it tries to load this bionic preload library through glibc, causing segfaults.

## Performance characteristics

### Overhead breakdown

| Layer | Overhead | Notes |
|-------|----------|-------|
| Wrapper (bash) | ~5ms | Argument parsing, path resolution |
| grun | ~10ms | Shell script, ld.so setup |
| ld.so | ~20ms | Dynamic library loading |
| env-preload.js | ~2ms | Read /proc/self/environ, parse, populate |
| **Total overhead** | **~37ms** | Added to every bun invocation |

Despite this overhead, bun still starts faster than native Node.js on Termux (~85ms vs ~137ms) because bun's runtime itself is lighter.

### Package install performance

`bun install` uses `copyfile` backend instead of the default `hardlink`. This is ~2-3x slower than hardlink on native Linux, but still ~2x faster than npm on Termux. The bottleneck is I/O, not CPU.

## Security notes

- The wrapper runs within Termux's sandbox (no root required)
- `/proc/self/environ` is readable only by the process owner (same UID)
- The preload script only activates when `process.env` is empty (grun scenario)
- No binary patching or ELF modification is performed (grun handles this transparently)
- All file operations stay within `~/.bun/` and the user's project directories
