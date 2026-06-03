# Binary Compatibility

## Current Binary

| Property | Value |
|----------|-------|
| Version | Bun v1.3.10 |
| Variant | `bun-linux-aarch64` (glibc) |
| Architecture | ARM64 (aarch64) |
| Size | ~100MB |
| Source | [oven-sh/bun](https://github.com/oven-sh/bun/releases) |
| Local name | `buno` ("bun original") |

## Why glibc, not musl?

Bun's `bun-linux-aarch64` is the glibc variant. Android uses bionic libc, not glibc. The C wrapper (`bun-termux`) bridges this by performing userland exec through glibc's dynamic linker.

The musl variant (`bun-linux-aarch64-musl`) does NOT work — musl and bionic are incompatible at the ABI level.

## Execution Path

```
bun (bash wrapper)
  -> bun-termux (C userland exec)
    -> ld-linux-aarch64.so.1 (glibc dynamic linker)
      -> bun-shim.so (LD_PRELOAD interception)
        -> buno (real bun binary)
```

The C wrapper maps the glibc dynamic linker's ELF segments into memory, constructs a new stack with environment variables, and jumps to the entry point. No `grun` needed.

## Running third-party bun-compiled binaries (`BUN_BINARY_PATH`)

The same userland-exec path works for **any** standalone binary produced by `bun build --compile`, not just `buno`. Set `BUN_BINARY_PATH` to point the wrapper at an alternate binary:

```bash
BUN_BINARY_PATH=/path/to/some-bun-binary bun-termux [args...]
```

The wrapper runs that binary through glibc's `ld-linux-aarch64.so.1` with `--preload bun-shim.so --library-path $PREFIX/glibc/lib`, passing the environment natively (unlike `grun`, which zeroes the env pointer). This is how **Claude Code 2.1.158** (a ~240 MB bun-compiled glibc binary that hardcodes the `/lib/ld-linux-aarch64.so.1` interpreter, absent on bionic) runs on Termux without `patchelf` — via a launcher:

```bash
export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-$PREFIX/tmp}"
BUN_BINARY_PATH="$HOME/.claude/binaries/claude-2.1.158/claude-binary" \
  exec "$HOME/.bun/bin/bun-termux" "$@"
```

Two caveats for such binaries:
- They embed their JS in a **bun-vfs blob keyed by byte offsets**. In-place edits that change byte length shift downstream offsets and corrupt the binary (it then reports *this* wrapper's bun version, e.g. `1.3.x`, instead of its own). Same-length overwrites are safe — bun-vfs is not checksummed.
- Any hardcoded `/tmp/...` paths fail on Termux (`/tmp` isn't writable). Honor the app's own tmpdir env var (`CLAUDE_CODE_TMPDIR` above) to redirect them into `$PREFIX/tmp`.

> **The launcher targets `bun-termux` directly, never the `bun` wrapper.** A running bun single-file executable exports `BUN_BINARY_PATH` (pointing at itself) into every shell it spawns, so child `bun` processes would otherwise re-exec it — e.g. inside a Claude Code session, `bun build`/`bun test` would silently launch Claude Code instead of bundling. The `bun` wrapper therefore `unset`s `BUN_BINARY_PATH` on entry; the launcher above is unaffected because it invokes `bun-termux` directly with the var set for that one `exec`.

## Platform Detection

Bun reports `process.platform = "linux"` and `process.arch = "arm64"`. This means:

- Native optional dependencies (rollup, esbuild) look for `linux-arm64` variants
- Some packages that check for `android` won't detect it
- `@rollup/rollup-linux-arm64-gnu` can be force-installed: `npm install @rollup/rollup-linux-arm64-gnu --force`

## Version History

| Version | Date | Notes |
|---------|------|-------|
| v1.3.10 | 2026-03 | Current, with C wrapper + shim |
| v1.3.9 | 2026-02 | First version with env-preload.js |
| v1.2.20 | 2025-08 | Initial grun-based setup |

## Upgrading

```bash
bash scripts/download-official-bun.sh 1.3.10
```
