# Comparison with Other Termux Bun Projects

Three projects solve the same core problem: running Bun (a glibc binary) on Android Termux (which uses bionic libc). Each takes a different approach to the userland exec technique and filesystem interception.

## Projects

| Project | Author | URL |
|---------|--------|-----|
| **bun-on-termux** | tribixbite | [github.com/tribixbite/bun-on-termux](https://github.com/tribixbite/bun-on-termux) |
| **bun-termux** | Happ1ness-dev | [github.com/Happ1ness-dev/bun-termux](https://github.com/Happ1ness-dev/bun-termux) |
| **bun-termux-loader** | kaan-escober | [github.com/kaan-escober/bun-termux-loader](https://github.com/kaan-escober/bun-termux-loader) |

## Architecture comparison

### bun-on-termux (this project)

```
bun (bash wrapper) -> bun-termux (C) -> ld.so -> bun-shim.so -> buno
     |                    |                          |
     |                    |                    intercepts: openat, stat,
     |                    |                    access, execve, link/linkat
     |                    |
     |               userland exec via mmap
     |
     handles: arg routing, package.json,
     --cwd injection, --backend=copyfile
```

Three-layer design: a bash wrapper handles high-level argument routing and package.json script parsing, a C binary performs userland exec, and an LD_PRELOAD shim intercepts filesystem syscalls. The bun binary (`buno`) is stored externally.

### bun-termux (Happ1ness-dev)

```
bun-termux (C) -> ld.so -> bun-shim.so -> buno
     |                          |
     |                    intercepts: openat, execve
     |
userland exec via mmap
(no bash wrapper — all args passed through)
```

Two-layer design: a C wrapper performs userland exec, and an LD_PRELOAD shim intercepts `openat` and `execve`. No bash wrapper — all arguments pass through to bun directly. The bun binary (`buno`) is stored externally.

### bun-termux-loader (kaan-escober)

```
my-app-termux (C wrapper + embedded bun) -> ld.so -> bunfs_shim.so -> bun
     |                                                   |
     |                                             intercepts: dlopen
     |
userland exec via mmap
(extracts embedded bun to cache on first run)
```

Self-contained design: bun's ELF binary (~92MB) is embedded inside the wrapper. On first run, it extracts to a cache directory. A minimal shim intercepts only `dlopen` for native library path rewriting. Designed primarily for `bun build --compile` output — compiled binaries are single-file executables.

## Feature comparison

### Core execution

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| Userland exec (mmap) | Yes | Yes | Yes |
| `/proc/self/exe` preserved | Yes | Yes | Yes |
| Bun binary location | External (`buno`) | External (`buno`) | Embedded (~92MB) |
| First-run cache extraction | N/A | N/A | Yes (FNV-1a hash key) |
| Env var passing | Native (stack) | Native (stack) | Native (stack) |
| LD_PRELOAD/LD_LIBRARY_PATH filtered | Yes | Yes | Yes |
| Startup overhead | ~30ms | ~25ms | ~25ms (cached) / ~3s (first run) |

### LD_PRELOAD shim coverage

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| `openat`/`openat64` | Yes | Yes | No |
| `open`/`open64` | Yes | No | No |
| `stat`/`lstat`/`fstatat` | Yes | No | No |
| `__xstat`/`__lxstat` | Yes | No | No |
| `access`/`faccessat` | Yes | No | No |
| `execve` (shebang translation) | Yes | Yes | No |
| `link`/`linkat` (hardlink fallback) | Yes | No | No |
| `dlopen` (path rewriting) | No | No | Yes |
| `/proc/stat` spoofing | Yes | Yes | No |

### What each shim fixes

| Problem | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|---------|-------------------|----------------|----------------------|
| `os.cpus()` returns data | Yes | Yes | No |
| `fs.existsSync('/')` works | Yes | No | No |
| `fs.statSync('/')` works | Yes | No | No |
| `fs.accessSync('/data')` works | Yes | No | No |
| `CouldntReadCurrentDirectory` | Fixed (openat redirect) | Fixed (openat redirect) | No |
| Shebangs (`#!/usr/bin/env node`) | Auto-translated | Auto-translated | Not handled |
| Hardlinks fail (EACCES on f2fs) | Auto copy fallback | Manual `--backend=copyfile` | Manual `--backend=copyfile` |
| Native lib paths (`/$bunfs/root/`) | N/A | N/A | dlopen rewrite |

### Bash wrapper and command handling

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| Bash wrapper | Yes | No | No |
| `bun run <script>` (package.json) | Parses and routes | Passthrough to bun | N/A |
| `bun install` auto flags | `--cwd` + `--backend=copyfile` | Manual | N/A |
| `bun init` / `bun create` | Works (skip `--config`) | Manual workarounds | N/A |
| bunx / `bun x` | Works | Works | N/A |
| Config injection (`--config=`) | Automatic | N/A | N/A |
| Stderr filtering | Yes (suppresses dir errors) | No | No |

### Build and compilation

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| Build system | Makefile | Makefile | Makefile + Python |
| Compiler | clang (native + cross) | clang (native + cross) | clang (native + cross) |
| Wrapper binary size | ~14KB | ~15KB | ~11KB |
| Shim binary size | ~20KB | ~12KB | ~4KB |
| `bun build --compile` | Works | Works + replace_runtime.py | Works (self-contained) |
| Compiled binary portability | Same device (needs glibc) | Same device (needs glibc) | Single file (cache needed) |

### Testing

|  | **bun-on-termux** | **bun-termux** | **bun-termux-loader** |
|--|-------------------|----------------|----------------------|
| Test suite | 80 tests, 18 categories | 8 tests | None |
| Categories | CLI, file exec, eval, REPL, test runner, build, pkg mgmt, scripts, bunx, create, APIs, env, low-level, dev server, network, workers, FFI, stress | Version, /proc/self/exe, env, os.cpus, shebang, fake-root, native modules, compile | N/A |
| Filter/select tests | `--category` and `--filter` | No | N/A |

## Design tradeoffs

### bun-on-termux: maximum compatibility

The three-layer design prioritizes compatibility and user experience. The bash wrapper handles edge cases that would be difficult in C (package.json parsing, init/create workarounds, --cwd injection). The expanded shim (stat, access, link interception) fixes issues the other projects leave to manual workarounds. The cost is a larger shim and ~5ms bash wrapper overhead.

### bun-termux: minimal wrapper

Happ1ness-dev's approach keeps the wrapper minimal — no bash, no argument routing, no package management helpers. Users handle `--backend=copyfile` and other flags manually. The shim covers the essentials (openat, execve, /proc/stat) but leaves stat/access/link to the caller. Good for users who want a thin layer with no magic.

### bun-termux-loader: self-contained binaries

kaan-escober's approach embeds the entire bun binary inside the wrapper, producing self-contained executables. The shim only handles `dlopen` for native library path rewriting. Designed primarily for distributing `bun build --compile` output as single-file binaries. The ~92MB embedded binary and first-run extraction are acceptable tradeoffs for portability.

## Credit

This project's C wrapper and shim are adapted from techniques in both reference implementations. The userland exec approach (mmap + inline asm stack switch) originates from kaan-escober's bun-termux-loader. The LD_PRELOAD shim with openat/execve interception is based on Happ1ness-dev's bun-termux.
