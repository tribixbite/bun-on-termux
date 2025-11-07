# Tmux Boot Session Aliases Guide

Complete reference for the tmux boot session management aliases in `~/.bash_aliases`.

## Quick Reference

### Basic Commands

| Alias | Description |
|-------|-------------|
| `tmb` | Attach to boot-session |
| `tmbk` | Kill boot-session |
| `tmbl` | List windows in boot-session |
| `tmbs` | List all tmux sessions |
| `tmbi` | Show boot session info (status, windows, commands) |
| `tmbb` | Quick attach (creates session if doesn't exist) |
| `tmbr` | Restart boot-session (kill and recreate) |

### Window Navigation (Current Setup: 0-5)

| Alias | Window | Project |
|-------|--------|---------|
| `tmb0` | 0 | cleverkeys |
| `tmb1` | 1 | CustomCamera |
| `tmb2` | 2 | Unexpected-Keyboard |
| `tmb3` | 3 | popcorn-mobile |
| `tmb4` | 4 | illustrate |
| `tmb5` | 5 | discord-irc |

### Advanced Functions

| Command | Usage | Description |
|---------|-------|-------------|
| `tmba` | `tmba <foldername>` | Add new repo to current session (temporary) |
| `tmbp` | `tmbp <foldername>` | Add repo permanently to startup.sh |
| `tmbw` | `tmbw <search>` | Switch to window by name (fuzzy search) |

## Detailed Usage

### Basic Operations

#### Attach to Boot Session
```bash
# Standard attach
tmb

# Quick attach (creates if missing)
tmbb
```

#### Check Session Status
```bash
# Full info display
tmbi

# Output:
# === Boot Session Info ===
# Status: ✓ Running
# Windows:
#   tmb0 - 0: cleverkeys (2 panes)
#   tmb1 - 1: CustomCamera (2 panes)
#   ...
```

#### List Windows
```bash
tmbl

# Output:
# 0: cleverkeys* (2 panes) [80x24]
# 1: CustomCamera (2 panes) [80x24]
# ...
```

#### Restart Session
```bash
# Kill and recreate with all repos
tmbr
```

### Window Navigation

#### Switch to Specific Window
```bash
# By number (if attached to session)
tmb0  # Go to cleverkeys
tmb3  # Go to popcorn-mobile

# By name (fuzzy search)
tmbw clever      # Finds "cleverkeys"
tmbw camera      # Finds "CustomCamera"
tmbw unexpected  # Finds "Unexpected-Keyboard"
```

**Note**: Window aliases (`tmb0`-`tmb5`) work from outside tmux to select window before attaching, or from within to switch windows.

### Adding New Repos

#### Temporary Addition (Current Session Only)

Add a repo to the running session without modifying startup.sh:

```bash
# From ~/git/
tmba my-project

# From subdirectory
tmba swype/another-keyboard

# Absolute path
tmba /path/to/repo
```

This creates a new tmux window running the `cc` command in the repo directory.

**Example**:
```bash
$ tmba ~/git/test-project
Adding test-project to boot-session as window 6...
✓ Window created: test-project (tmb6 to switch)

To make this permanent, add to ~/.termux/boot/startup.sh:
  "$HOME/git/test-project"
```

New dynamic alias created: `tmb6`

#### Permanent Addition

Add a repo to `~/.termux/boot/startup.sh` so it loads on every boot:

```bash
# Add to startup.sh
tmbp my-project

# Output:
# ✓ Added to startup.sh: $HOME/git/my-project
#
# To apply immediately: tmba my-project
# To see changes: cat ~/.termux/boot/startup.sh | grep -A 10 'repos='
```

Then restart session to apply:
```bash
tmbr
```

### Inside tmux Session

Once attached with `tmb`, use standard tmux keybindings:

#### Window Management
```bash
Ctrl+b then 0-9    # Switch to window 0-9
Ctrl+b then n      # Next window
Ctrl+b then p      # Previous window
Ctrl+b then w      # Window list (interactive)
Ctrl+b then ,      # Rename window
```

#### Pane Management
```bash
Ctrl+b then ←→↑↓   # Switch between panes
Ctrl+b then z      # Zoom/unzoom current pane
Ctrl+b then %      # Split vertically
Ctrl+b then "      # Split horizontally
Ctrl+b then x      # Kill current pane
```

#### Session Management
```bash
Ctrl+b then d      # Detach from session
Ctrl+b then :      # Command prompt
```

## Common Workflows

### Daily Development Workflow

```bash
# Morning: attach to boot session
tmbb

# Work on different projects
# (Inside tmux)
Ctrl+b 0           # Switch to cleverkeys
Ctrl+b 3           # Switch to popcorn-mobile

# Evening: detach (keeps running)
Ctrl+b d
```

### Adding a New Project

```bash
# Method 1: Temporary (for testing)
tmba new-project
tmb6                # Switch to it
# Test it out...

# Method 2: Permanent (if keeping)
tmbp new-project
tmbr                # Restart to apply

# Method 3: Manual edit
vim ~/.termux/boot/startup.sh
# Add to repos array: "$HOME/git/new-project"
tmbr                # Restart
```

### Finding a Window

```bash
# List all windows with grep
tmbl | grep -i camera

# Fuzzy search and switch
tmbw camera

# Use tmux native list
tmb
Ctrl+b w           # Interactive window list
```

### Session Recovery

```bash
# Check if session exists
tmbs

# If session is broken, restart
tmbk
~/.termux/boot/startup.sh

# Or use restart alias
tmbr
```

## Advanced Tips

### Create Additional Window Aliases

Edit `~/.bash_aliases` to add more window aliases:
```bash
alias tmb6='tmux select-window -t boot-session:6'
alias tmb7='tmux select-window -t boot-session:7'
# etc...
```

Then reload:
```bash
source ~/.bash_aliases
```

### Auto-attach on Terminal Start

Add to `~/.bashrc` (after the aliases source):
```bash
# Auto-attach to boot session if not in tmux
if [ -z "$TMUX" ] && tmux has-session -t boot-session 2>/dev/null; then
    echo "Boot session active. Attaching..."
    exec tmux attach -t boot-session
fi
```

**Note**: This will auto-attach every time you open Termux.

### Create Named Sessions

Besides boot-session, create additional sessions for different contexts:
```bash
# Work session
tmux new-session -d -s work
tmux send-keys -t work "cd ~/work" C-m

# Personal session
tmux new-session -d -s personal
tmux send-keys -t personal "cd ~/personal" C-m

# Attach to specific session
tmux attach -t work
```

### Session Switcher Function

Add to `~/.bash_aliases`:
```bash
# Switch between sessions
tms() {
  local sessions=($(tmux list-sessions -F '#S' 2>/dev/null))

  if [ ${#sessions[@]} -eq 0 ]; then
    echo "No tmux sessions running"
    return 1
  fi

  echo "Available sessions:"
  for i in "${!sessions[@]}"; do
    echo "  $i: ${sessions[$i]}"
  done

  if [ -n "$1" ]; then
    tmux attach -t "${sessions[$1]}"
  else
    tmux attach -t "${sessions[0]}"
  fi
}
```

Usage:
```bash
tms      # Attach to first session
tms 1    # Attach to second session
```

## Troubleshooting

### Aliases Not Working

```bash
# Reload bash configuration
source ~/.bashrc

# Or in new shell
exec bash
```

### Functions Not Found

```bash
# Check if aliases file is sourced
grep "bash_aliases" ~/.bashrc

# Should show:
# if [ -f ~/.bash_aliases ]; then
#     . ~/.bash_aliases
# fi
```

### Window Numbers Changed

```bash
# Check current window layout
tmbi

# Update aliases in ~/.bash_aliases to match
# Or use tmbw for fuzzy search instead
```

### Session Doesn't Exist

```bash
# Create session manually
~/.termux/boot/startup.sh

# Or use quick attach (auto-creates)
tmbb
```

### Repo Not Found Errors

When using `tmba` or startup script:
```bash
# Verify repo exists
ls -d ~/git/my-project

# Check repos array in startup script
cat ~/.termux/boot/startup.sh | grep -A 10 'repos='
```

### Panes Show Wrong Directory

The startup script uses `send-keys` with `cd`. If panes are in wrong directory:
```bash
# Manually navigate
cd ~/git/correct-repo

# Or restart session
tmbr
```

## Configuration Files

### Location of Key Files

- **Aliases**: `~/.bash_aliases`
- **Startup Script**: `~/.termux/boot/startup.sh`
- **Bash Config**: `~/.bashrc`
- **Boot Log**: `~/.termux/boot.log`

### Editing Configuration

```bash
# Edit aliases
vim ~/.bash_aliases
source ~/.bash_aliases  # Reload

# Edit startup script
vim ~/.termux/boot/startup.sh
tmbr                    # Restart session

# Edit bashrc
vim ~/.bashrc
source ~/.bashrc        # Reload
```

## Reference Links

- tmux cheatsheet: https://tmuxcheatsheet.com/
- Termux:Boot wiki: https://wiki.termux.com/wiki/Termux:Boot
- Full boot setup guide: `docs/TERMUX_BOOT_SETUP.md`

## Summary

| Task | Command |
|------|---------|
| Attach to session | `tmb` or `tmbb` |
| Switch to window N | `tmbN` (e.g., `tmb0`, `tmb1`) |
| Find window by name | `tmbw <name>` |
| Add temp repo | `tmba <repo>` |
| Add permanent repo | `tmbp <repo>` |
| Restart session | `tmbr` |
| Session info | `tmbi` |
| List windows | `tmbl` |
| Kill session | `tmbk` |
| Detach (inside tmux) | `Ctrl+b d` |

**Quick Start**: Type `tmb` to attach, `Ctrl+b` then number to switch windows, `Ctrl+b d` to detach.
