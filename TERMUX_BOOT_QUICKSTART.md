# Termux Boot - Quick Start

## What You Need

1. **Termux:Boot app** (separate from Termux) - Install from F-Droid
2. **termux-api package**: `pkg install termux-api`
3. **Termux:API app** (for wake-lock) - Install from F-Droid

## Verify Setup

```bash
# Check Termux:Boot is installed
pm list packages | grep termux.boot
# Should show: package:com.termux.boot

# Check termux-api commands
which termux-wake-lock termux-wake-unlock
```

## Your Current Setup ✅

**Fixed script**: `~/.termux/boot/startup.sh`

Creates a tmux session named `boot-session` with 6 windows (one per repo), each running the `cc` command in the repo directory.

## How to Use

### After Device Boots

```bash
# Attach to the boot session
tmux attach -t boot-session

# Or check all sessions
tmux ls
```

### Navigate tmux

```bash
# Switch between windows
Ctrl+b then 0-3  # Window number

# Switch between panes in a window
Ctrl+b then arrow keys

# Detach from session (keeps it running)
Ctrl+b then d

# List all windows
Ctrl+b then w
```

### Test Without Rebooting

```bash
# Kill old session if exists
tmux kill-session -t boot-session

# Run the boot script manually
~/.termux/boot/startup.sh

# Attach to session
tmux attach -t boot-session
```

### Check Boot Logs

```bash
cat ~/.termux/boot.log
```

## Customize

Edit `~/.termux/boot/startup.sh` to:
- Add/remove repos from the `repos=()` array
- Change tmux session name from `boot-session`
- Modify commands run in panes (currently `cc`)

## Troubleshooting

**Scripts not running at boot:**
1. Open Termux:Boot app once after installation
2. Reboot device
3. Grant battery optimization exemptions

**Commands fail:**
- Use full paths: `/data/data/com.termux/files/usr/bin/tmux`
- Check script is executable: `chmod +x ~/.termux/boot/startup.sh`

**tmux session not created:**
```bash
# Check tmux is installed
pkg install tmux

# Test script manually
bash -x ~/.termux/boot/startup.sh
```

## Full Documentation

See `docs/TERMUX_BOOT_SETUP.md` for complete guide with alternatives and advanced usage.
