# Troubleshooting Bun on Termux

## Environment variables empty (`process.env` has 0 keys)

**Symptom**: `process.env.HOME`, `process.env.PATH`, etc. are all `undefined`.

**Cause**: If using the old grun-based setup, glibc's `ld.so` zeroes the C `environ` pointer when invoked as a program loader.

**Fix**: Upgrade to the C wrapper (`bun-termux`), which passes env vars natively:

```bash
cd bun-on-termux
make install
cp wrappers/bun ~/.bun/bin/bun-minimal
```

Verify: `bun -e 'console.log(Object.keys(process.env).length)'` should show 90+.

## "CouldntReadCurrentDirectory" error

**Symptom**: `error: An internal error occurred (CouldntReadCurrentDirectory)`

**Cause**: Bun traverses the CWD's parent directories. On Android, reading `/data/data/` fails with EACCES.

**Fix**: The shim (`bun-shim.so`) intercepts `openat()` and redirects restricted directory reads to a safe location. Ensure the shim is installed:

```bash
ls -la ~/.bun/lib/bun-shim.so
# If missing, rebuild:
cd bun-on-termux && make install
```

## `bun run <script>` fails or runs wrong command

**Symptom**: `bun run dev` doesn't execute the script from package.json.

**Cause**: The wrapper parses package.json scripts using `grep`/`sed`. Complex scripts with nested quotes or multi-line values may not parse correctly.

**Fix**: Use simple scripts, or run the file directly:

```bash
bun src/index.ts
```

## `bun install` EACCES — installs 0 packages

**Symptom**: `EACCES: Permission denied` during install.

**Cause**: Android f2fs blocks hardlinks. The wrapper auto-injects `--backend=copyfile`, but if you're calling bun-termux directly, you need to pass it manually.

**Fix**: Ensure you're using the wrapper, or pass `--backend=copyfile`:

```bash
bun install --backend=copyfile
```

If the cache was corrupted:

```bash
rm -rf ~/.bun/install/cache
mkdir -p ~/.bun/install/cache
```

## Segmentation faults

**Symptom**: Bun crashes with segfault on startup.

**Cause**: Usually one of:
1. Wrong binary variant (x86 instead of aarch64)
2. Missing or corrupted shim
3. glibc-runner / glibc not properly installed

**Fix**:

```bash
# Check binary architecture
file ~/.bun/bin/buno
# Should show: ELF 64-bit LSB executable, ARM aarch64

# Test C wrapper directly
~/.bun/bin/bun-termux --version

# Test grun fallback
grun ~/.bun/bin/buno --version

# Check glibc installation
ls -la /data/data/com.termux/files/usr/glibc/lib/ld-linux-aarch64.so.1
pacman -Q glibc-runner glibc
```

## `bun build --compile` output not standalone

**Symptom**: Compiled binaries work on this device but not on other Android devices.

**Cause**: `bun build --compile` on Termux produces binaries that still depend on the Termux glibc environment. They are not truly standalone.

**Workaround**: Bundle to JS instead:

```bash
bun build --outdir=dist index.ts
echo '#!/bin/bash
bun dist/index.js "$@"' > app
chmod +x app
```

## `fs.watch()` doesn't trigger

**Symptom**: File system watches don't fire on some Android devices.

**Cause**: Android's inotify implementation may be restricted in certain kernel configurations.

**Workaround**: Use polling-based watch if available, or implement manual file stat comparison.

## `spawnSync` can't resolve bare command names

**Symptom**: `spawnSync("tmux", [...])` returns `{ status: undefined }`.

**Fix**: Always resolve the full binary path:

```typescript
const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr";
const tmuxBin = `${prefix}/bin/tmux`;
Bun.spawnSync([tmuxBin, "list-sessions"]);
```

## `am` / `app_process` commands silently fail

**Symptom**: `am start` exits 0 but the intent never fires.

**Cause**: The C wrapper filters `LD_PRELOAD` from the environment. Termux's `libtermux-exec-ld-preload.so` is required by `app_process`.

**Fix**: Pass `LD_PRELOAD` explicitly:

```typescript
const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr";
const env = {
    ...process.env,
    LD_PRELOAD: `${prefix}/lib/libtermux-exec-ld-preload.so`
};
Bun.spawnSync(["am", "start", ...args], { env });
```

## `process.platform` reports "linux" instead of "android"

**Cause**: Bun is a glibc binary compiled for `linux-aarch64`.

**Implications**: Platform-gated packages (Playwright, esbuild) see "linux" not "android". This is usually beneficial — Playwright works under bun but not node on Android.

## Debugging

### Wrapper debug

```bash
# Add set -x after the shebang in ~/.bun/bin/bun-minimal:
set -x
bun run dev
# Remove when done
```

### C wrapper debug

```bash
# Test C wrapper directly
~/.bun/bin/bun-termux --version
~/.bun/bin/bun-termux -e 'console.log(process.env.HOME)'

# Test shim effects
~/.bun/bin/bun-termux -e 'console.log(require("os").cpus().length)'
```

### System info for bug reports

```bash
echo "=== System ==="
uname -a
echo "=== Versions ==="
bun --version
~/.bun/bin/bun-termux --version
grun --version 2>/dev/null
echo "=== Binary ==="
file ~/.bun/bin/buno
ls -la ~/.bun/bin/bun-termux ~/.bun/lib/bun-shim.so
echo "=== glibc ==="
pacman -Q glibc-runner glibc 2>/dev/null
```
