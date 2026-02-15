# Binary Compatibility Guide

## Current binary

| Property | Value |
|----------|-------|
| **Version** | Bun v1.3.9 |
| **Variant** | `bun-linux-aarch64` (glibc) |
| **Architecture** | ARM64 (aarch64) |
| **Size** | ~100MB |
| **Location** | `~/.bun/bin/buno` |
| **SHA256** | `a2c2862bcc1fd1c0b3a8dcdc8c7efb5e2acd871eb20ed2f17617884ede81c844` |
| **Source** | [oven-sh/bun v1.3.9](https://github.com/oven-sh/bun/releases/tag/bun-v1.3.9) |

## Which variant to use

Bun publishes multiple Linux ARM64 variants:

| File | Variant | Works with grun? |
|------|---------|-----------------|
| `bun-linux-aarch64.zip` | **glibc** | **Yes** — use this one |
| `bun-linux-aarch64-musl.zip` | musl | Not tested; grun provides glibc, not musl |
| `bun-linux-aarch64-baseline.zip` | glibc (no advanced CPU features) | Should work; try if main variant segfaults |

Use the **glibc** variant (`bun-linux-aarch64.zip`). Despite early assumptions that musl might be more compatible, the glibc variant is what glibc-runner is designed to run. The dynamic linker and shared libraries provided by grun's glibc environment match the glibc variant's expectations.

## Naming convention

The binary is stored as `buno` ("bun original") so the wrapper script can claim the `bun` command name:

```
~/.bun/bin/bun   <- bash wrapper script (this project)
~/.bun/bin/buno  <- real bun binary from official release
```

## Verifying a binary

### SHA256 verification

```bash
# Download the official binary
BUN_VERSION="1.3.9"
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun-official.zip

# Extract
unzip -o ~/.bun/tmp/bun-official.zip -d ~/.bun/tmp/

# Compare hashes
sha256sum ~/.bun/bin/buno
sha256sum ~/.bun/tmp/bun-linux-aarch64/bun
# Both should match
```

### ELF verification

```bash
file ~/.bun/bin/buno
# Expected: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV),
#           dynamically linked, interpreter /lib/ld-linux-aarch64.so.1,
#           for GNU/Linux 3.7.0, ...
```

Key things to check:
- `ARM aarch64` — correct architecture
- `dynamically linked` — needs glibc libraries (provided by grun)
- `interpreter /lib/ld-linux-aarch64.so.1` — glibc dynamic linker (grun redirects this)

### grun compatibility check

```bash
# Library resolution
grun --findlib ~/.bun/bin/buno
# Should output: "searching libraries was successful"

# Basic execution
grun ~/.bun/bin/buno --version
# Should output: 1.3.9

# Full wrapper execution
bun --version
# Should output: 1.3.9
```

## Upgrading

```bash
# 1. Backup current binary
cp ~/.bun/bin/buno ~/.bun/bin/buno-$(bun --version).bak

# 2. Download new version
BUN_VERSION="1.3.9"  # change to target version
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip" \
  -o ~/.bun/tmp/bun.zip

# 3. Extract and install
unzip -o ~/.bun/tmp/bun.zip -d ~/.bun/tmp/
cp ~/.bun/tmp/bun-linux-aarch64/bun ~/.bun/bin/buno
chmod +x ~/.bun/bin/buno

# 4. Verify
bun --version

# 5. Run tests
bun -e 'console.log("env vars:", Object.keys(process.env).length)'
bun -e 'console.log("HOME:", process.env.HOME)'
```

If the new version crashes or behaves incorrectly:

```bash
# Restore backup
cp ~/.bun/bin/buno-*.bak ~/.bun/bin/buno
```

## Version history

| Version | Variant | SHA256 | Status |
|---------|---------|--------|--------|
| v1.3.9 | linux-aarch64 (glibc) | `a2c2862bcc1fd1c0b3a8dcdc8c7efb5e2acd871eb20ed2f17617884ede81c844` | **Current** |
| v1.2.20 | linux-aarch64 (glibc) | `7b184f1a36bf2fe6424d074af11c49391ba942abd1de4762adf7d96143b43839` | Previous, verified |

## Known binary issues

- **glibc version sensitivity**: The binary links against specific glibc symbols. If glibc-runner's glibc is too old, some symbols may be missing. Keep glibc-runner updated: `pacman -Syu glibc-runner glibc`.
- **CPU feature requirements**: The main `bun-linux-aarch64` variant may use advanced ARM CPU features. If it segfaults on older SoCs, try the `-baseline` variant.
- **Binary size**: ~100MB is large for mobile storage. Consider cleanup of old backups: `rm ~/.bun/bin/buno-*.bak`.
