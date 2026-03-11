#!/data/data/com.termux/files/usr/bin/env python3
"""
Replace the bun runtime in a `bun build --compile` binary with the
bun-termux wrapper, reducing binary size from ~100MB to ~15KB.

The output binary requires buno + bun-shim.so + glibc-runner on the
target device (i.e., another Termux+glibc-runner install). Without
this script, compiled binaries embed the full bun runtime and are
self-contained on the same device.

How it works:
  bun build --compile produces: [bun_runtime_elf][bundled_data][marker][size_u64]
  This script replaces bun_runtime_elf with the wrapper binary,
  keeping bundled_data and the marker intact.

Based on: https://github.com/Happ1ness-dev/bun-termux helper_scripts/replace_runtime.py
Original technique: https://github.com/kaan-escober/bun-termux-loader build.py
"""

import struct
import sys
import os
import shutil
from pathlib import Path

ELF_MAGIC = b'\x7fELF'
BUN_MARKER = b'---- Bun! ----'


def find_elf_end(data: bytes) -> int:
    """Find the byte offset where the ELF binary ends (after all segments/sections)."""
    if len(data) < 64 or data[:4] != ELF_MAGIC:
        raise ValueError("Not a valid ELF file")
    if data[4] != 2:
        raise ValueError("Only 64-bit ELF supported")

    e_phoff = struct.unpack('<Q', data[32:40])[0]
    e_shoff = struct.unpack('<Q', data[40:48])[0]
    e_phentsize, e_phnum = struct.unpack('<HH', data[54:58])
    e_shentsize, e_shnum = struct.unpack('<HH', data[58:62])

    end = 0

    # Find the end of the last PT_LOAD segment
    for i in range(e_phnum):
        ph = e_phoff + i * e_phentsize
        p_type = struct.unpack('<I', data[ph:ph + 4])[0]
        if p_type == 1:  # PT_LOAD
            p_offset = struct.unpack('<Q', data[ph + 8:ph + 16])[0]
            p_filesz = struct.unpack('<Q', data[ph + 32:ph + 40])[0]
            seg_end = p_offset + p_filesz
            if seg_end > end:
                end = seg_end

    # Section headers may extend beyond the last segment
    if e_shoff > 0 and e_shnum > 0:
        sh_end = e_shoff + e_shentsize * e_shnum
        if sh_end > end:
            end = sh_end

    return end


def replace_runtime(input_path: str, output_path: str = None,
                    wrapper_path: str = None) -> None:
    """Replace the bun runtime in a compiled binary with the wrapper."""
    input_file = Path(input_path).resolve()

    # Determine output path and backup strategy
    if output_path is not None:
        output_file = Path(output_path).resolve()
        backup_file = None
    else:
        backup_file = input_file.with_suffix(input_file.suffix + '.bak')
        output_file = input_file

    # Default wrapper: bun-termux (the C wrapper that does userland exec)
    if wrapper_path is None:
        bun_install = os.environ.get('BUN_INSTALL', os.path.expanduser('~/.bun'))
        wrapper_path = os.path.join(bun_install, 'bin', 'bun-termux')
    wrapper_file = Path(wrapper_path).resolve()

    # Validate inputs
    if not input_file.exists():
        print(f"Error: input not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    if not wrapper_file.exists():
        print(f"Error: wrapper not found: {wrapper_file}", file=sys.stderr)
        sys.exit(1)

    print(f"Input:   {input_file} ({input_file.stat().st_size:,} bytes)")
    with open(input_file, 'rb') as f:
        input_data = f.read()

    # Verify this is a bun compiled binary
    if BUN_MARKER not in input_data[-256:]:
        print("Error: not a bun compiled binary (missing '---- Bun! ----' marker)",
              file=sys.stderr)
        sys.exit(1)

    print(f"Wrapper: {wrapper_file} ({wrapper_file.stat().st_size:,} bytes)")
    with open(wrapper_file, 'rb') as f:
        wrapper_data = f.read()

    if len(wrapper_data) < 64 or wrapper_data[:4] != ELF_MAGIC:
        print("Error: wrapper is not a valid ELF binary", file=sys.stderr)
        sys.exit(1)

    try:
        original_elf_end = find_elf_end(input_data)
    except ValueError as e:
        print(f"Error: failed to parse input ELF: {e}", file=sys.stderr)
        sys.exit(1)

    embedded_data = input_data[original_elf_end:]
    print(f"Runtime: {original_elf_end:,} bytes -> {len(wrapper_data):,} bytes")
    print(f"Payload: {len(embedded_data):,} bytes (preserved)")

    # Build output: wrapper + embedded data, update trailing size field
    output_data = bytearray(wrapper_data) + embedded_data
    output_data[-8:] = struct.pack('<Q', len(output_data))

    # Backup original if overwriting
    if backup_file is not None:
        if backup_file.exists():
            print(f"Error: backup already exists: {backup_file}", file=sys.stderr)
            sys.exit(1)
        shutil.copy2(input_file, backup_file)
        print(f"Backup:  {backup_file}")

    with open(output_file, 'wb') as f:
        f.write(output_data)
    os.chmod(output_file, 0o755)

    reduction = (1 - len(output_data) / len(input_data)) * 100
    print(f"Output:  {output_file} ({len(output_data):,} bytes, {reduction:.0f}% smaller)")
    print(f"\nNote: output requires buno + bun-shim.so + glibc-runner on target device")


def restore_runtime(backup_path: str) -> None:
    """Restore a compiled binary from its .bak backup."""
    backup_file = Path(backup_path).resolve()
    if not backup_file.exists():
        print(f"Error: backup not found: {backup_file}", file=sys.stderr)
        sys.exit(1)

    original_file = backup_file.with_suffix('')
    if original_file.exists():
        os.remove(original_file)
    shutil.copy2(backup_file, original_file)
    os.chmod(original_file, 0o755)
    print(f"Restored: {original_file}")


def main():
    args = sys.argv[1:]

    if '-h' in args or '--help' in args or len(args) < 1:
        print("""Usage: python replace-runtime.py <command> [options]

Commands:
  replace <binary> [output]   Replace embedded bun runtime with wrapper
  restore <binary.bak>        Restore from backup

Options:
  --wrapper <path>            Wrapper binary (default: ~/.bun/bin/bun-termux)

Examples:
  # Replace runtime in-place (backs up to myapp.bak)
  python replace-runtime.py replace ./myapp

  # Replace to a separate file
  python replace-runtime.py replace ./myapp ./myapp-small

  # Restore from backup
  python replace-runtime.py restore ./myapp.bak

  # Use custom wrapper
  python replace-runtime.py replace ./myapp --wrapper /path/to/wrapper

Compiled binary layout:
  [bun_runtime_elf][bundled_js_data][---- Bun! ----][total_size_u64]

  'replace' swaps bun_runtime_elf with the ~15KB bun-termux wrapper.
  The output binary requires Termux + glibc-runner + buno + bun-shim.so
  on the target device to run.""")
        sys.exit(0 if '-h' in args or '--help' in args else 1)

    command = args[0]

    if command == 'restore':
        if len(args) < 2:
            print("Error: restore requires a .bak file path", file=sys.stderr)
            sys.exit(1)
        restore_runtime(args[1])
        return

    if command == 'replace':
        args = args[1:]
    # Also accept bare path for backwards compat
    elif os.path.exists(command):
        args = [command] + args[1:]
    else:
        print(f"Error: unknown command '{command}'", file=sys.stderr)
        sys.exit(1)

    if len(args) < 1:
        print("Error: input binary path required", file=sys.stderr)
        sys.exit(1)

    input_path = args[0]
    output_path = None
    wrapper_path = None

    i = 1
    while i < len(args):
        if args[i] == '--wrapper' and i + 1 < len(args):
            wrapper_path = args[i + 1]
            i += 2
        elif output_path is None and not args[i].startswith('-'):
            output_path = args[i]
            i += 1
        else:
            print(f"Error: unexpected argument: {args[i]}", file=sys.stderr)
            sys.exit(1)

    replace_runtime(input_path, output_path, wrapper_path)


if __name__ == '__main__':
    main()
