# Termux Configuration

## Package Manager

This project requires **termux-pacman** (not the default `pkg`/`apt`).

```bash
pacman --version       # Verify pacman
pacman -S glibc-runner # Required for glibc dynamic linker
pacman -S glibc        # Required for glibc headers (building shim)
pkg install clang git  # Required for building C components
```

## Glibc-Runner

glibc-runner provides the glibc dynamic linker at:
```
/data/data/com.termux/files/usr/glibc/lib/ld-linux-aarch64.so.1
```

The C wrapper (`bun-termux`) loads this linker via userland exec. `grun` is no longer needed as the primary execution method but remains useful for debugging.

## Installed File Layout

```
~/.bun/
  bin/
    bun           -> bun-minimal (symlink)
    bun-minimal   <- bash wrapper script
    bun-termux    <- C userland exec wrapper
    buno          <- real bun binary (v1.3.10, ~100MB)
    bunfig.toml   <- bun config (passed via --config=)
  lib/
    bun-shim.so   <- LD_PRELOAD interception shim
  tmp/
    fake-root/    <- safe directory for shim directory redirects
  install/
    cache/        <- package download cache
    global/       <- globally installed packages
```

## Environment Variables

The C wrapper passes all environment variables natively through the constructed stack. Key variables available inside bun:

| Variable | Source | Notes |
|----------|--------|-------|
| `HOME` | Termux | `/data/data/com.termux/files/home` |
| `PATH` | Termux | Includes `~/.bun/bin` |
| `PREFIX` | Termux | `/data/data/com.termux/files/usr` |
| `TERM` | Termux | Terminal type |
| `BUN_FAKE_ROOT` | C wrapper | Set automatically for shim |

## Wrapper Architecture

The bash wrapper (`~/.bun/bin/bun-minimal`) handles:

1. **Argument routing**: Dispatches to correct execution mode
2. **Path resolution**: Converts relative paths to absolute
3. **Package.json parsing**: Extracts and routes scripts
4. **Package management**: Injects `--cwd` and `--backend=copyfile`
5. **Stderr filtering**: Suppresses "Cannot read directory" noise

Commands that skip `--config=` (to avoid arg parsing bugs):
- `bun init` — `--config` makes bun interpret "init" as folder name
- `bun create` — same issue

## Debugging

```bash
# Test C wrapper directly
~/.bun/bin/bun-termux --version
~/.bun/bin/bun-termux -e 'console.log(process.env.HOME)'

# Check env var count
bun -e 'console.log(Object.keys(process.env).length)'

# Test shim effects
bun -e 'console.log(require("os").cpus().length)'

# Wrapper debug (add set -x after shebang in bun-minimal)
```
