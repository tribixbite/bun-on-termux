# Troubleshooting Bun on Termux

## Common Issues

### "CouldntReadCurrentDirectory" Error

**Symptom**: `bun run <script>` fails with directory reading error
**Cause**: Android filesystem restrictions in Bun's `configureEnvForRun()`
**Solution**: Use the wrapper script which handles this automatically

```bash
# This fails:
bun run dev

# This works (wrapper handles it):
~/.bun/bin/bun run dev
```

### Environment Variables Not Passed

**Symptom**: `process.env.VARIABLE` is undefined in Bun scripts
**Cause**: glibc-runner doesn't pass environment variables to child processes
**Solutions**:
1. Use config files instead of environment variables
2. Hardcode values temporarily
3. Create wrapper scripts that set variables
4. Use `bunx` which properly passes environment variables

```bash
# Won't work with main bun wrapper:
export API_KEY=abc123
bun script.js

# Works with bunx:
export API_KEY=abc123
bunx your-cli-tool

# Workaround - use config file:
echo '{"apiKey": "abc123"}' > config.json
bun script.js
```

### Segmentation Faults

**Symptom**: Bun crashes with segfault
**Cause**: Wrong binary being used
**Solution**: Ensure you're using the working `buno` binary

```bash
# Check which binary the wrapper uses:
head -n 10 ~/.bun/bin/bun

# Should show grun ~/.bun/bin/buno
```

### Package Installation Issues

**Symptom**: `bun install` hangs or fails
**Cause**: Network issues or lifecycle scripts
**Solutions**:
1. Use `--ignore-scripts` flag
2. Configure `bunfig.toml` with `auto = false` (this file is read by Bun)
3. Use `backend = "copyfile"` in bunfig.toml for Termux compatibility

```bash
bun install --ignore-scripts
# or
bun i --backend=copyfile
```

### Build/Compilation Failures

**Symptom**: `bun build --compile` fails
**Cause**: ARM64 Android limitations
**Solutions**:
1. Use regular bundling without compilation
2. Create shell script wrappers instead

```bash
# Instead of:
bun build --compile --outfile=app index.ts

# Use:
bun build --outdir=dist index.ts
echo '#!/bin/bash\nbun dist/index.js "$@"' > app
chmod +x app
```

## Advanced Debugging

### Check grun Status

```bash
grun --version
grun --help
```

### Verify Binary Compatibility

```bash
# Test direct execution:
grun ~/.bun/bin/buno --version

# Test wrapper:
~/.bun/bin/bun --version
```

### Monitor Resource Usage

```bash
# Check memory during package install:
bun install &
top -p $!
```

### Network Debugging

```bash
# Test registry connectivity:
curl -I https://registry.npmjs.org/

# Use different registry:
bun install --registry=https://registry.npmjs.org/
```

## Environment Specific Issues

### Termux-Pacman Conflicts

If using termux-pacman, ensure no conflicts with regular Termux packages:

```bash
# Check package manager:
which pacman
which pkg

# Verify glibc installation:
pacman -Qs glibc
```

### Android Version Compatibility

Some Android versions have stricter restrictions:

- Android 7+: Basic functionality
- Android 10+: Enhanced security requires workarounds
- Android 14+: Additional filesystem restrictions

### Storage Issues

Termux internal storage may have limitations:

```bash
# Check available space:
df -h $HOME

# Use external storage if needed:
bun --cwd=/sdcard/project install
```

## Performance Optimization

### Memory Usage

```bash
# Use --smol flag for lower memory:
bun --smol script.js

# Configure garbage collection:
bun --expose-gc script.js
```

### Network Performance

```bash
# Use local cache:
bun install --prefer-offline

# Parallel downloads:
bun install --concurrent=2
```

### Bunx Package Not Found

**Symptom**: `bunx package` fails with "Could not find executable" error
**Cause**: Package doesn't provide expected binary name
**Solutions**:
1. Check what binaries the package actually provides
2. Use `--package` flag to specify binary name explicitly
3. Check if package is compatible with ARM64/Android

```bash
# Check what binaries a package provides:
bunx --package=your-package --help

# Sometimes package name differs from binary name:
bunx typescript --version  # Uses 'tsc' binary automatically
```

### Bunx Cache Issues

**Symptom**: Old versions being used or cache corruption
**Cause**: Stale cache or permission issues
**Solutions**:
1. Clear bunx cache manually
2. Check cache directory permissions

```bash
# Clear bunx cache:
rm -rf ~/.bun/tmp/bunx-*

# Check cache permissions:
ls -la ~/.bun/tmp/
```

## Getting Help

1. Run the comprehensive test suite: `./test-bun-comprehensive.sh`
2. Test bunx functionality: `./init test-bunx`
3. Check the detailed output for specific failing commands
4. Consult the main README.md for architecture details
5. Open an issue with test results and system information

### System Information to Include

```bash
termux-info
bun --version
grun --version 2>/dev/null || echo "grun not available"
cat /proc/version
```