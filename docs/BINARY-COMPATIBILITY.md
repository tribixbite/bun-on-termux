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
