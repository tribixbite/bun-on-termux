# Termux Package Manager Migration Guide: APT to Pacman

## Current Situation Analysis

You have a **hybrid installation** where:
- **555 packages** installed via apt/dpkg (legacy)
- **103 packages** installed via pacman (current)
- **Many overlapping packages** causing file conflicts

## Understanding the Problem

When you install packages with pacman that were previously installed with apt, you get file conflicts because:
1. Both package managers track the same files independently
2. dpkg database still thinks it owns files that pacman is trying to install
3. Using `--overwrite='*'` works but leaves the dpkg database inconsistent

## Proper Migration Approaches

### Option 1: Clean Migration (Recommended for New Setups)
Complete reinstall using the official bootstrap method:

```bash
# 1. Backup important data
tar -czf ~/termux-backup.tar.gz ~/.bashrc ~/.zshrc ~/.ssh ~/.config ~/git

# 2. Download pacman bootstrap
wget https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-aarch64.zip

# 3. Create new usr directory
cd /data/data/com.termux/files
mkdir usr-new
cd usr-new
unzip ~/bootstrap-aarch64.zip

# 4. Process symlinks
cat SYMLINKS.txt | awk -F "←" '{system("ln -s '"'"'"$1"'"'"' '"'"'"$2"'"'"')}'

# 5. Replace usr directory
cd ..
rm -rf usr
mv usr-new usr

# 6. Initialize pacman
pacman-key --init
pacman-key --populate
pacman -Syu
```

### Option 2: Gradual Migration (For Existing Setups)

Since you already have both systems installed, here's the safer approach:

#### Step 1: Document Current State
```bash
# List all apt packages
dpkg -l | grep '^ii' | awk '{print $2}' > ~/apt-installed.txt

# List all pacman packages  
pacman -Q > ~/pacman-installed.txt

# Find packages only in apt
comm -23 <(sort ~/apt-installed.txt) <(pacman -Q | awk '{print $1}' | sort) > ~/apt-only.txt
```

#### Step 2: Handle Conflicts Properly
```bash
# For each package you want to migrate to pacman:

# 1. First, remove from dpkg database (keeps files)
dpkg --remove --force-depends package-name

# 2. Then install with pacman (will detect existing files)
pacman -S package-name --overwrite='*'

# OR for multiple packages:
for pkg in openssh krb5 libdb libedit ldns libresolv-wrapper; do
    dpkg --remove --force-depends $pkg 2>/dev/null
    pacman -S $pkg --overwrite='*' --noconfirm
done
```

#### Step 3: Clean Up APT Packages Safely
```bash
# Remove apt packages that have pacman equivalents
# BE CAREFUL - some packages might have different names

# First, identify safe-to-remove packages
dpkg -l | grep '^ii' | awk '{print $2}' | while read pkg; do
    if pacman -Q ${pkg} 2>/dev/null; then
        echo "Can remove from dpkg: $pkg"
    fi
done > ~/safe-to-remove.txt

# Review the list carefully, then remove
cat ~/safe-to-remove.txt | while read line; do
    pkg=$(echo $line | awk '{print $5}')
    dpkg --remove --force-depends $pkg
done
```

## Managing Package Conflicts

### When Installing New Packages

```bash
# Check if package exists in dpkg first
dpkg -l | grep package-name

# If it exists, remove from dpkg first
dpkg --remove --force-depends package-name

# Then install with pacman
pacman -S package-name
```

### Automated Conflict Resolution Script

Create `~/fix-package-conflict.sh`:

```bash
#!/data/data/com.termux/files/usr/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

PACKAGE="$1"

# Check if installed via dpkg
if dpkg -l | grep -q "^ii  $PACKAGE "; then
    echo "Removing $PACKAGE from dpkg database..."
    dpkg --remove --force-depends "$PACKAGE" 2>/dev/null
fi

# Install/reinstall with pacman
echo "Installing $PACKAGE with pacman..."
pacman -S "$PACKAGE" --overwrite='*' --noconfirm

echo "Done! $PACKAGE is now managed by pacman."
```

Make it executable:
```bash
chmod +x ~/fix-package-conflict.sh
```

Usage:
```bash
~/fix-package-conflict.sh openssh
```

## Important Warnings

### DO NOT:
- ❌ Run `apt update` or `apt upgrade` after switching to pacman
- ❌ Mix installation methods (some packages apt, some pacman)
- ❌ Delete `/var/lib/dpkg` directory (contains package database)

### DO:
- ✅ Always use `pkg` wrapper (it detects the active manager)
- ✅ Use `pacman -Syu` for system updates
- ✅ Remove packages from dpkg before installing with pacman
- ✅ Keep backups of important configurations

## Checking Current Package Manager

```bash
# Method 1: Check pkg wrapper
source /data/data/com.termux/files/usr/bin/termux-setup-package-manager
echo "Active manager: $TERMUX_APP_PACKAGE_MANAGER"

# Method 2: Check which is functional
if pacman -Q &>/dev/null; then
    echo "Pacman is active"
elif dpkg -l &>/dev/null; then  
    echo "APT/dpkg is active"
fi
```

## Post-Migration Cleanup

Once fully migrated to pacman:

```bash
# Remove apt cache (saves space)
rm -rf /data/data/com.termux/cache/apt

# Remove apt lists
rm -rf /data/data/com.termux/files/usr/var/lib/apt/lists/*

# Keep dpkg database for reference (small)
# But mark as migrated
touch /data/data/com.termux/files/usr/var/lib/dpkg/MIGRATED_TO_PACMAN
```

## SSH Installation (Corrected Method)

For your specific case with OpenSSH:

```bash
# 1. Remove apt versions first
for pkg in openssh openssh-sftp-server krb5 libdb libedit ldns libresolv-wrapper; do
    dpkg --remove --force-depends $pkg 2>/dev/null
done

# 2. Clean install with pacman
pacman -S openssh --overwrite='*' --noconfirm

# 3. Start SSH service
sshd

# 4. Set password for SSH access
passwd

# 5. Connect from another device
# ssh -p 8022 username@your-ip
```

## Troubleshooting

### "exists in filesystem" errors
```bash
# Option 1: Remove from dpkg first
dpkg --remove --force-depends package-name
pacman -S package-name

# Option 2: Force overwrite (less clean)
pacman -S package-name --overwrite='*'
```

### Package not found in pacman
```bash
# Search with different terms
pacman -Ss keyword

# Check Termux User Repository (TUR)
pacman -Ss --repo tur package-name

# Some packages have different names:
# apt: python3 → pacman: python
# apt: nodejs-lts → pacman: nodejs
```

### Broken dependencies
```bash
# Fix pacman database
pacman -Syu --overwrite='*'

# Remove orphaned packages
pacman -Rns $(pacman -Qtdq)

# Reinstall base packages
pacman -S base-devel --overwrite='*'
```

## Summary

You're in a transitional state with both package managers. The safest approach is:

1. **New packages**: Always use `pacman -S`
2. **Conflicts**: Remove from dpkg first, then install with pacman
3. **Updates**: Only use `pacman -Syu`, never `apt upgrade`
4. **Long term**: Gradually migrate all packages to pacman

The `--overwrite='*'` flag you used is a quick fix but leaves the dpkg database inconsistent. For a cleaner system, remove packages from dpkg before installing with pacman.