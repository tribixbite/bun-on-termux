# Termux Boot Setup Guide

Complete guide for running scripts and sessions automatically when your Android device boots.

## Prerequisites

### 1. Install Termux:Boot App

**Required**: You must install the separate Termux:Boot app from F-Droid:
```
https://f-droid.org/packages/com.termux.boot/
```

**Note**: This is a separate app from Termux itself. You need both installed.

### 2. Verify Installation
```bash
# Check if Termux:Boot is installed
pm list packages | grep termux.boot
# Should show: package:com.termux.boot
```

### 3. Grant Necessary Permissions

After installing Termux:Boot:
1. Open the Termux:Boot app once (it will show a simple screen)
2. Reboot your device to activate the boot receiver
3. Grant autostart/battery optimization exemptions in Android settings

## Setup Boot Scripts

### Directory Structure
```bash
# Create boot directory if it doesn't exist
mkdir -p ~/.termux/boot
chmod 700 ~/.termux/boot

# Scripts in this directory run alphabetically at boot
ls ~/.termux/boot/
```

### Basic Boot Script Example

Create `~/.termux/boot/01-startup.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash
# Must use full shebang path for boot scripts

# Acquire wake lock to prevent sleep
termux-wake-lock

# Your commands here
echo "Boot script started at $(date)" >> "$HOME/boot.log"

# Example: Start sshd
sshd

# Example: Start a background service
# nohup node ~/server.js > ~/server.log 2>&1 &

# Release wake lock
termux-wake-unlock
```

Make it executable:
```bash
chmod +x ~/.termux/boot/01-startup.sh
```

## Using tmux for Multiple Sessions

### Best Practice: tmux Sessions

Create `~/.termux/boot/02-tmux-sessions.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash

termux-wake-lock

# Start tmux session with multiple windows
tmux new-session -d -s boot

# Window 0: Project A
tmux rename-window -t boot:0 "project-a"
tmux send-keys -t boot:0 "cd ~/git/project-a && npm run dev" C-m

# Window 1: Project B
tmux new-window -t boot:1 -n "project-b"
tmux send-keys -t boot:1 "cd ~/git/project-b" C-m

# Window 2: Monitoring
tmux new-window -t boot:2 -n "monitor"
tmux send-keys -t boot:2 "htop" C-m

# Select first window
tmux select-window -t boot:0

termux-wake-unlock

echo "Tmux session 'boot' created with $(tmux list-windows -t boot | wc -l) windows" >> "$HOME/boot.log"
```

### Attach to Boot Session
```bash
# After boot, attach to the session
tmux attach -t boot

# Or from another Termux window
tmux attach -t boot
```

## Alternative: Open Multiple Termux Windows

Create `~/.termux/boot/03-termux-windows.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash

# Function to open new Termux window
open_termux_window() {
  local title="$1"
  local command="$2"

  am start \
    -n com.termux/.app.TermuxActivity \
    -e com.termux.execute.command "$command" \
    -e com.termux.execute.arguments "" \
    --es com.termux.execute.background true

  sleep 1  # Delay between windows
}

# Open windows for different projects
open_termux_window "Server" "cd ~/server && npm start"
open_termux_window "Monitor" "htop"
open_termux_window "Shell" "bash"
```

**Limitation**: Cannot easily manage or reconnect to these windows.

## Your Current Setup (Fixed)

Your repos-based tmux setup (already applied to `~/.termux/boot/startup.sh`):
```bash
#!/data/data/com.termux/files/usr/bin/bash

termux-wake-lock

repos=(
  "$HOME/git/swype/cleverkeys"
  "$HOME/git/swype/CustomCamera"
  "$HOME/git/swype/Unexpected-Keyboard"
  "$HOME/git/pop/popcorn-mobile"
)

tmux new-session -d -s boot-session

window_index=0
for repo in "${repos[@]}"; do
  if [ -d "$repo" ]; then
    name=$(basename "$repo")

    if [ $window_index -eq 0 ]; then
      tmux rename-window -t boot-session:0 "$name"
      tmux send-keys -t boot-session:0 "cd '$repo'" C-m
    else
      tmux new-window -t boot-session:$window_index -n "$name"
      tmux send-keys -t boot-session:$window_index "cd '$repo'" C-m
    fi

    # Split pane for 'cc' command
    tmux split-window -t boot-session:$window_index -h
    tmux send-keys -t boot-session:$window_index.1 "cd '$repo' && cc" C-m

    window_index=$((window_index + 1))
  fi
done

tmux select-window -t boot-session:0
termux-wake-unlock

echo "[$(date)] Boot session created" >> "$HOME/.termux/boot.log"
```

After boot, attach with:
```bash
tmux attach -t boot-session
```

## Testing Without Rebooting

### Test Boot Scripts Manually
```bash
# Run all boot scripts
~/.termux/boot/startup.sh

# Check if tmux session was created
tmux ls

# Attach to session
tmux attach -t boot-session
```

### Simulate Boot Receiver
```bash
# Trigger boot receiver (if Termux:Boot is installed)
am broadcast -a com.termux.boot_completed -n com.termux.boot/.BootReceiver
```

## Debugging Boot Issues

### Check Boot Logs
```bash
# Your custom log
cat ~/.termux/boot.log

# Android system log
logcat | grep -i termux
```

### Common Issues

1. **Scripts not running**
   - Ensure Termux:Boot app is installed and opened once
   - Reboot device after first Termux:Boot installation
   - Check script permissions: `chmod +x ~/.termux/boot/*.sh`

2. **Commands not found**
   - Use full paths in boot scripts: `/data/data/com.termux/files/usr/bin/tmux`
   - Or ensure PATH is set: `export PATH=/data/data/com.termux/files/usr/bin:$PATH`

3. **Wake lock issues**
   - Install termux-api: `pkg install termux-api`
   - Install Termux:API app from F-Droid
   - Grant API permissions

4. **tmux session not persisting**
   - Boot scripts run in background, tmux sessions persist
   - Use `tmux attach -t boot-session` to reconnect
   - Check `tmux ls` to see active sessions

### Verify Wake Lock
```bash
# Check if wake lock is active
termux-wake-lock
ps aux | grep wake-lock

# Release wake lock
termux-wake-unlock
```

## Advanced: Systemd-style Services

For more control, consider using a process manager:

### Using Runit (Termux's service manager)
```bash
# Install runit
pkg install termux-services

# Restart Termux after installation
exit

# Create service directory
mkdir -p ~/.termux/sv/myservice
```

Create `~/.termux/sv/myservice/run`:
```bash
#!/data/data/com.termux/files/usr/bin/bash
exec 2>&1
cd ~/git/myproject
exec npm start
```

```bash
chmod +x ~/.termux/sv/myservice/run

# Enable service
sv-enable myservice

# Start service
sv up myservice

# Check status
sv status myservice
```

## Boot Script Execution Order

Scripts in `~/.termux/boot/` run alphabetically:
```bash
01-environment.sh   # Set environment variables
02-services.sh      # Start background services
03-tmux.sh         # Create tmux sessions
99-cleanup.sh      # Final cleanup/logging
```

## Best Practices

1. **Keep scripts simple** - Complex logic can fail silently
2. **Log everything** - Use `>> $HOME/boot.log` for debugging
3. **Use wake locks** - Prevent sleep during critical operations
4. **Test manually first** - Verify scripts work before rebooting
5. **Use tmux** - Better session management than multiple Termux windows
6. **Set timeouts** - Prevent hanging on network operations
7. **Handle failures gracefully** - Check if directories exist before cd

## Example: Complete Production Setup

`~/.termux/boot/startup.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash

LOG="$HOME/.termux/boot.log"
echo "=== Boot started: $(date) ===" >> "$LOG"

termux-wake-lock

# Start SSH server
if command -v sshd &> /dev/null; then
  sshd
  echo "Started sshd" >> "$LOG"
fi

# Create development tmux session
if command -v tmux &> /dev/null; then
  # Kill old session if exists
  tmux kill-session -t dev 2>/dev/null

  # Create new session
  tmux new-session -d -s dev -n main
  tmux send-keys -t dev:0 "cd ~/git/main-project" C-m

  # Add monitoring window
  tmux new-window -t dev:1 -n monitor
  tmux send-keys -t dev:1 "htop" C-m

  echo "Created tmux session 'dev'" >> "$LOG"
fi

# Start background services
# nohup ~/scripts/background-service.sh >> "$LOG" 2>&1 &

termux-wake-unlock

echo "=== Boot completed: $(date) ===" >> "$LOG"
```

## Attach on Termux Startup

Add to `~/.bashrc` to auto-attach to boot session:
```bash
# Auto-attach to boot session if it exists and not already in tmux
if [ -z "$TMUX" ] && tmux has-session -t boot-session 2>/dev/null; then
  echo "Boot session detected. Attach with: tmux attach -t boot-session"
  # Uncomment to auto-attach:
  # exec tmux attach -t boot-session
fi
```

## Useful Commands

```bash
# List all tmux sessions
tmux ls

# Attach to specific session
tmux attach -t boot-session

# Kill session
tmux kill-session -t boot-session

# List windows in session
tmux list-windows -t boot-session

# Create new window in existing session
tmux new-window -t boot-session -n "new-window"

# Switch between windows
# Ctrl+b then number (0-9)
# Or: Ctrl+b then n (next) / p (previous)

# Detach from session
# Ctrl+b then d
```

## Resources

- Termux:Boot Wiki: https://wiki.termux.com/wiki/Termux:Boot
- tmux cheatsheet: https://tmuxcheatsheet.com/
- Termux Services: https://wiki.termux.com/wiki/Termux-services
