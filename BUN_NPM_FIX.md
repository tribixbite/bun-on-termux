# Bun/NPM Setup Fix Summary

## Issues Found

### 1. Corrupted Global Packages
**Problem**: Empty package directories for `bn.js` and `err-code` in `~/.bun/install/global/node_modules/`
- These were installed but contained no files
- Caused EACCES errors during package operations
- Prevented bunx from working properly

**Fix Applied**:
```bash
rm -rf ~/.bun/install/global/node_modules/bn.js
rm -rf ~/.bun/install/global/node_modules/err-code
bun pm cache rm
```

### 2. Bun Doctor Error
**Problem**: `bun doctor` fails with "CouldntReadCurrentDirectory" error
- This appears to be a bug in bun v1.2.20 (bun-minimal)
- Not critical for normal operations
- Related to how bun-minimal handles directory operations in Termux

**Status**: Known issue, doesn't affect bunx functionality after corruption fix

### 3. webtorrent-health Package Misunderstanding
**Problem**: `webtorrent-health` is a library, not a CLI tool
- Has no `bin` field in package.json
- Cannot be executed directly with bunx
- Must be used programmatically

**Solution**: Created CLI wrapper at `~/check-torrent-health.js`

## Working Commands

### Using the CLI Wrapper
```bash
# Install dependencies (already done)
cd ~ && npm install webtorrent-health

# Use the wrapper
node ~/check-torrent-health.js "magnet:?xt=urn:btih:HASH&tr=tracker-url"
```

### Alternative: Create Function in .bashrc
Add to `~/.bashrc`:
```bash
check_torrent() {
  node ~/check-torrent-health.js "$1"
}
```

Then use:
```bash
check_torrent "magnet:?xt=urn:btih:..."
```

### For Your Original Loop
```bash
magnets=(
  'magnet:?xt=urn:btih:f231c62635aadfb0e4d1f45ddc7b5b6c5592b275&tr=udp://tracker.openbittorrent.com:80'
  'magnet:?xt=urn:btih:724648552d517756117b47b3a7f5f62962f2629e&tr=udp://tracker.openbittorrent.com:80'
)

for m in "${magnets[@]}"; do
  echo "==> $m"
  node ~/check-torrent-health.js "$m"
done
```

**Note**: Your original magnets were missing tracker URLs (`&tr=...`). You need to add trackers for the health check to work.

## Common Tracker URLs
```
&tr=udp://tracker.openbittorrent.com:80
&tr=udp://tracker.opentrackr.org:1337
&tr=udp://tracker.coppersurfer.tk:6969
&tr=udp://exodus.desync.com:6969
&tr=udp://tracker.torrent.eu.org:451
```

## Prevention

To avoid similar issues in the future:

1. **Clear bun cache periodically**:
   ```bash
   bun pm cache rm
   ```

2. **Check package type before using bunx**:
   ```bash
   npm view PACKAGE_NAME  # Check if it has a "bin" field
   ```

3. **Use npm for reliability in Termux**:
   - npm is more stable in Termux than bun's package management
   - Use bunx for execution, npm for installation

4. **Monitor global packages**:
   ```bash
   ls ~/.bun/install/global/node_modules/
   ```

## Current Status

✅ Corrupted packages removed
✅ Bun cache cleared
✅ bunx working (tested with cowsay)
✅ CLI wrapper created for webtorrent-health
✅ Dependencies installed via npm
⚠️ bun doctor still shows error (non-critical)

## Files Created

- `~/check-torrent-health.js` - CLI wrapper for webtorrent-health
- `~/node_modules/` - npm packages (webtorrent-health + dependencies)
