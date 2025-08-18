# Binary Compatibility Guide

This guide covers different Bun binary sources and their compatibility with Termux/glibc-runner.

## Binary Sources Comparison

| Source | Compatibility | Testing | Pros | Cons |
|--------|--------------|---------|------|------|
| **Included (`buno`)** | ✅ Verified | ✅ Pre-tested | Guaranteed to work | May not be latest version |
| **Official Releases** | ⚠️ Variable | ⚠️ User testing required | Latest features | May have compatibility issues |
| **Self-compiled** | ❓ Unknown | ❓ Extensive testing needed | Custom optimizations | Complex, time-intensive |

## Included Binary Details

### Source and Testing
- **Version**: Bun v1.2.20 (as of repository creation)
- **Build**: ARM64 musl-based binary
- **Testing**: Verified with glibc-runner v2.0-3 on Android 7+
- **Compatibility**: Known to work with all wrapper functions

### Why This Binary Works
- Built with musl libc (more compatible with Android)
- Tested specifically with glibc-runner
- Verified to handle directory reading issues gracefully
- Compatible with copyfile backend requirements

## Official Bun Releases

### Advantages
- **Latest Features**: Always up-to-date with newest Bun capabilities
- **Official Support**: Directly from Bun team
- **Security Updates**: Includes latest security patches
- **Performance**: May include recent performance improvements

### Potential Issues
- **glibc Dependencies**: May expect different glibc version
- **Android Compatibility**: Not specifically tested for Android/Termux
- **Directory Reading**: May have different behavior with filesystem restrictions
- **Backend Requirements**: Might need different package management backends

### Testing Official Binaries

After downloading an official binary, test these scenarios:

#### Basic Functionality
```bash
# Test direct execution
grun ~/.bun/bin/buno --version
grun ~/.bun/bin/buno -e 'console.log("Hello")'

# Test wrapper integration
bun --version
bun -e 'console.log("Wrapper test")'
```

#### Package Management
```bash
# Test local install
cd /tmp && mkdir bun-test && cd bun-test
echo '{}' > package.json
bun add lodash

# Test global install (should use copyfile backend automatically)
bun i -g prettier

# Test script execution
echo '{"scripts":{"test":"echo works"}}' > package.json
bun run test
```

#### Advanced Features
```bash
# Test TypeScript
echo 'const x: string = "TypeScript"; console.log(x);' > test.ts
bun test.ts

# Test build system
echo 'export default "built";' > build-test.js
bun build build-test.js --outdir=dist

# Test Bun APIs
bun -e 'console.log("Bun version:", Bun.version)'
```

## Version Compatibility Matrix

### Known Working Versions
- **v1.2.20**: Included binary, fully tested
- **v1.2.x**: Generally compatible with minor differences
- **v1.1.x**: Older but should work with wrapper

### Potentially Problematic Versions
- **v1.3.x+**: May have new filesystem requirements
- **Pre-v1.0**: Missing features, not recommended
- **Canary builds**: Experimental, use with caution

## Troubleshooting Official Binaries

### Common Issues and Solutions

#### "CouldntReadCurrentDirectory" Errors
**Symptom**: Bun fails with directory reading errors
**Solution**: 
1. Use wrapper script (should handle automatically)
2. Ensure grun is properly configured
3. Test in a simple directory structure

#### Segmentation Faults
**Symptom**: Binary crashes with segfault
**Solution**:
1. Verify architecture: `file ~/.bun/bin/buno` should show ARM64
2. Check glibc-runner: `grun --version` should work
3. Try older Bun version
4. Fall back to included binary

#### Package Installation Failures
**Symptom**: `bun install` or `bun add` fails with permission errors
**Solution**:
1. Wrapper should auto-add `--backend=copyfile` for global installs
2. For local installs, try: `bun install --backend=copyfile`
3. Check disk space and permissions

#### Performance Issues
**Symptom**: Slow execution or high memory usage
**Solution**:
1. Try `bun --smol` flag for lower memory usage
2. Check available RAM: `free -h`
3. Clear package cache: `rm -rf ~/.bun/install/cache`

### When to Use Official vs Included Binary

#### Use Official Binary When:
- You need the latest Bun features
- You're willing to do compatibility testing
- You want to stay current with security updates
- You're comfortable troubleshooting issues

#### Use Included Binary When:
- You want guaranteed compatibility
- You prioritize stability over latest features
- You're new to Bun on Termux
- You need a working setup immediately

## Binary Updating Strategy

### Conservative Approach
1. Keep included binary as backup
2. Test official binary in isolated environment
3. Run comprehensive test suite
4. Only switch after confirming compatibility

### Automated Update Script
```bash
#!/bin/bash
# Safe binary update script

# Backup current working binary
cp ~/.bun/bin/buno ~/.bun/bin/buno.backup

# Download and test new binary
./scripts/download-official-bun.sh

# Run test suite
if ./test-bun-comprehensive.sh; then
    echo "✅ New binary works, keeping it"
    rm ~/.bun/bin/buno.backup
else
    echo "❌ New binary failed tests, restoring backup"
    cp ~/.bun/bin/buno.backup ~/.bun/bin/buno
fi
```

## Reporting Compatibility Issues

When reporting issues with official binaries:

1. **Include versions**: Bun version, Android version, glibc-runner version
2. **Test results**: Output of test suite
3. **Specific errors**: Full error messages and stack traces
4. **Comparison**: Whether included binary works
5. **Environment**: Output of `termux-info`

### Issue Template
```
**Bun Version**: [from bun --version]
**Official/Included**: Official binary from releases
**Android Version**: [from termux-info]
**glibc-runner Version**: [from grun --version]
**Test Suite Results**: [pass/fail summary]
**Specific Issue**: [detailed description]
**Error Messages**: [full error output]
**Workaround**: [if any found]
```

This helps identify patterns and improve compatibility over time.