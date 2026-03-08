# Troubleshooting Bun on Termux

## Environment variables empty (`process.env` has 0 keys)

**Symptom**: `process.env.HOME`, `process.env.PATH`, etc. are all `undefined`.

**Cause**: glibc's `ld.so`, when invoked as a program loader by grun, zeroes the C `environ` pointer. The kernel-level environment in `/proc/self/environ` is intact but the C runtime doesn't expose it.

**Fix**: The wrapper script passes `--preload env-preload.js` which reads `/proc/self/environ` and populates `process.env`. If you're seeing empty env vars, check:

```bash
# Verify the preload script exists
ls -la ~/.bun/bin/env-preload.js

# Verify the wrapper is using --preload
head -50 ~/.bun/bin/bun | grep preload

# Test env vars directly
bun -e 'console.log(Object.keys(process.env).length, "env vars")'
# Should show 100+ env vars
```

If env vars are still missing, ensure you're using the wrapper (`bun`) and not calling `grun buno` directly.

## "CouldntReadCurrentDirectory" error

**Symptom**: `error: An internal error occurred (CouldntReadCurrentDirectory)` or `error loading current directory`

**Cause**: Bun calls `std::env::current_dir()` which uses glibc's `getcwd()`. When running through ld.so, the directory traversal through `/data/data/com.termux/files/...` fails.

**Fix**: The wrapper handles this by `cd`-ing to `~/.bun/tmp` before exec and converting all file args to absolute paths. If you see this error:

```bash
# Ensure the safe directory exists
mkdir -p ~/.bun/tmp

# Verify you're using the wrapper, not calling buno directly
which bun
# Should show ~/.bun/bin/bun

# Test from any directory
cd /some/project && bun --version
```

## "Cannot read directory" stderr noise

**Symptom**: Warnings like `Cannot read directory '/data/data/...'` on stderr.

**Cause**: Even with the safe CWD, bun's internal path resolution attempts to traverse restricted Android paths. These errors are non-fatal.

**Fix**: The wrapper filters these via `2> >(grep -v "Cannot read directory" >&2)`. If you still see them, you may be calling bun through a script that bypasses the wrapper.

## `bun run <script>` fails or runs wrong command

**Symptom**: `bun run dev` doesn't execute the script from package.json, or runs with wrong arguments.

**Cause**: The wrapper parses `package.json` scripts using `grep`/`sed`. Complex scripts with nested quotes, multi-line values, or uncommon JSON formatting may not parse correctly.

**Fix**:

```bash
# Check what the wrapper sees
grep '"dev"' package.json

# For complex scripts, use a shell script file instead:
# package.json: "dev": "bash scripts/dev.sh"

# Or run the file directly:
bun src/index.ts
```

## `bun install` EACCES — installs 0 packages

**Symptom**: `EACCES: Permission denied while installing <package>` on every package, and `node_modules/` stays empty (0 packages installed). Directories may be created but files inside are missing.

**Cause**: Two issues compound:
1. **CWD mismatch**: The wrapper `cd`s to `~/.bun/tmp` before exec, so bun looks for `package.json` in the wrong directory.
2. **Hardlinks blocked**: Android f2fs blocks hardlinks (`EACCES`), and bun uses hardlinks by default.

**Fix**: Update to the latest `bun-minimal` wrapper, which auto-injects `--cwd` and `--backend=copyfile` for all package management commands. After updating, `bun install` and `bun add` should work without any extra flags.

If you're on an older wrapper version, pass the flags manually:

```bash
bun install --cwd $(pwd) --backend=copyfile
```

If the cache was deleted, recreate it first:

```bash
mkdir -p ~/.bun/install/cache
```

## `bun add` shows EACCES permission warnings

**Symptom**: `EACCES: Permission denied while installing <package>` but the install still succeeds.

**Cause**: Stale entries in `~/.bun/install/cache/` with different ownership or permissions from a previous session or different execution context.

**Fix**:

```bash
# Clear the install cache
rm -rf ~/.bun/install/cache
mkdir -p ~/.bun/install/cache

# Or fix permissions
chmod -R u+rw ~/.bun/install/cache/
```

## `bunx` / `bun x` fails

**Symptom**: `bun x cowsay` errors with `CouldntReadCurrentDirectory`.

**Cause**: The bunx execution path tries to read the working directory for package resolution. The safe-CWD workaround only partially helps because bunx needs to find local `node_modules/.bin` relative to the project.

**Workaround**: Use `npx` as a fallback:

```bash
# Instead of:
bunx cowsay "hello"

# Use:
npx cowsay "hello"
```

## Segmentation faults

**Symptom**: Bun crashes with segfault immediately on startup.

**Cause**: Usually one of:
1. Wrong binary variant (x86 instead of aarch64)
2. Corrupted binary
3. glibc-runner not properly installed
4. Termux's `LD_PRELOAD` conflicting with glibc

**Fix**:

```bash
# Check binary architecture
file ~/.bun/bin/buno
# Should show: ELF 64-bit LSB executable, ARM aarch64

# Test grun directly
grun ~/.bun/bin/buno --version

# Check glibc-runner installation
grun --version
pacman -Q glibc-runner

# If LD_PRELOAD causes issues, grun should handle this,
# but you can test without it:
unset LD_PRELOAD
grun ~/.bun/bin/buno --version
```

## `bun build --compile` fails

**Symptom**: Single-file compilation errors or the compiled binary won't execute.

**Cause**: Android filesystem restrictions prevent the compiled binary from running natively. The compiled output would also need grun to execute.

**Workaround**: Use bundling without compilation:

```bash
# Instead of:
bun build --compile --outfile=app index.ts

# Bundle to JS, then run with bun:
bun build --outdir=dist index.ts

# Create a launcher script:
echo '#!/bin/bash
bun dist/index.js "$@"' > app
chmod +x app
```

## Package install hangs or is slow

**Symptom**: `bun install` takes very long or hangs.

**Cause**: Network issues, lifecycle scripts hanging, or the `hardlink` backend failing silently.

**Fix**:

```bash
# Ensure copyfile backend is being used (check bunfig.toml)
grep backend ~/.bun/bin/bunfig.toml
# Should show: backend = "copyfile"

# Skip lifecycle scripts
bun install --ignore-scripts

# Force copyfile backend explicitly
bun install --backend=copyfile

# Check network
curl -I https://registry.npmjs.org/
```

## `+` operator broken in `bun -e`

**Symptom**: `bun -e 'console.log(1+1)'` outputs `1` instead of `2`, or errors.

**Cause**: The `+` character gets consumed or reinterpreted during argument passing through the bash wrapper -> grun -> ld.so chain.

**Workaround**: Use a temp file instead of `-e`:

```bash
# Instead of:
bun -e 'console.log(1+1)'

# Use:
echo 'console.log(1+1)' > /tmp/test.js && bun /tmp/test.js
```

## Wrong bun version or old binary

**Symptom**: `bun --version` shows an unexpected version.

**Fix**:

```bash
# Check which bun is being used
which bun
type bun

# Check the actual binary
grun ~/.bun/bin/buno --version

# If there are multiple bun installations, check PATH order
echo $PATH | tr ':' '\n' | grep -i bun
```

## `spawnSync` can't resolve bare command names

**Symptom**: `spawnSync("tmux", ["list-sessions"])` returns `{ status: undefined, stdout: null }`. No error, no output — it silently fails.

**Cause**: Bun's spawnSync doesn't resolve bare command names via the PATH environment variable the way Node.js or bash do. PATH lookups fail silently.

**Fix**: Always resolve the full binary path before calling spawnSync:

```typescript
import { existsSync } from "fs";
import { join } from "path";

function resolveTermuxBin(name: string): string {
  const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr";
  const candidate = join(prefix, "bin", name);
  if (existsSync(candidate)) return candidate;
  return name; // fallback — will likely fail under bun
}

// Use resolved paths:
const TMUX_BIN = resolveTermuxBin("tmux");
const ADB_BIN = resolveTermuxBin("adb");
spawnSync(TMUX_BIN, ["list-sessions"], { encoding: "utf-8" });
```

**Affected commands**: tmux, adb, am, termux-am — any binary invoked via spawnSync.

## `am` / `app_process` commands silently fail (LD_PRELOAD stripped)

**Symptom**: `spawnSync("am", ["start", "-n", "com.termux/..."])` returns exit code 0 but the intent never fires. No error output. Activities don't launch, services don't start.

**Cause**: Bun's glibc runner strips `LD_PRELOAD` from the environment. Termux's `libtermux-exec-ld-preload.so` is an exec interceptor required by `app_process` (the JVM wrapper that `$PREFIX/bin/am` uses internally). Without this library preloaded, `app_process` runs but fails to communicate with Android's ActivityManager — it returns success but the intent is silently dropped.

**Why it's hard to diagnose**: The command exits 0, produces no stderr, and the binary runs to completion. Only the absence of the expected side effect reveals the problem.

**Fix**: Explicitly set `LD_PRELOAD` in the env passed to spawnSync:

```typescript
function amEnv(): NodeJS.ProcessEnv {
  const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr";
  const ldPreload = join(prefix, "lib", "libtermux-exec-ld-preload.so");
  return { ...process.env, LD_PRELOAD: ldPreload };
}

const AM_BIN = resolveTermuxBin("am");
spawnSync(AM_BIN, ["startservice", "--user", "0", ...], {
  timeout: 5000, stdio: "ignore", env: amEnv()
});
```

**Verification**: Create a marker file via RunCommandService — if the file appears, am is working:

```bash
# From bun — test am with LD_PRELOAD fix:
bun -e "
const {spawnSync} = require('child_process');
const env = {...process.env, LD_PRELOAD: '/data/data/com.termux/files/usr/lib/libtermux-exec-ld-preload.so'};
spawnSync('/data/data/com.termux/files/usr/bin/am', [
  'startservice', '--user', '0',
  '-n', 'com.termux/com.termux.app.RunCommandService',
  '-a', 'com.termux.RUN_COMMAND',
  '--es', 'com.termux.RUN_COMMAND_PATH', '/data/data/com.termux/files/usr/bin/touch',
  '--esa', 'com.termux.RUN_COMMAND_ARGUMENTS', '/data/data/com.termux/files/usr/tmp/am-test-marker',
  '--ez', 'com.termux.RUN_COMMAND_BACKGROUND', 'true',
], {timeout: 5000, env});
"
# Check: ls -la $PREFIX/tmp/am-test-marker
```

## `process.platform` reports "linux" instead of "android"

**Symptom**: Platform-gated packages behave differently under bun vs node. For example, Playwright rejects "android" but accepts "linux".

**Cause**: Bun's binary is compiled for `linux-aarch64` (glibc), so it reports `process.platform === "linux"`. Node.js on Termux is compiled for `android-aarch64` (bionic), reporting `"android"`.

**Implications**:
- **Playwright**: Use `bun` to run `@playwright/mcp` or playwright scripts — node will error with "Unsupported platform: android"
- **esbuild**: Bun installs `linux-arm64-gnu` variant; node needs `android-arm64` (use `fix-android-binaries.mjs`)
- **Platform checks**: Any `if (process.platform === "linux")` check passes under bun but fails under node on the same device

**Workaround**: Run platform-gated tools under bun. If node is required, check if the package provides an android-specific variant.

## Debugging

### Wrapper debug

Check what the wrapper is doing by adding `set -x` temporarily:

```bash
# Add to top of ~/.bun/bin/bun (after the shebang):
set -x

# Run your command, observe the trace output
bun run dev

# Remove set -x when done
```

### grun debug

```bash
# Basic strace
grun --debug 1 ~/.bun/bin/buno --version

# Verbose strace
grun --debug 3 ~/.bun/bin/buno --version

# Check library loading
grun --findlib ~/.bun/bin/buno
```

### System information for bug reports

```bash
echo "=== System ==="
uname -a
cat /proc/version

echo "=== Termux ==="
termux-info 2>/dev/null || echo "termux-info not available"

echo "=== Versions ==="
bun --version
node --version 2>/dev/null
grun --version 2>/dev/null

echo "=== Binary ==="
file ~/.bun/bin/buno
ls -la ~/.bun/bin/

echo "=== Package Manager ==="
pacman -Q glibc-runner glibc 2>/dev/null
```
