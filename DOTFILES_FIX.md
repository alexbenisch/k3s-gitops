# Dotfiles Setup Fix

## Date: 2025-11-03

## Problem Identified

The dotfiles setup script (`~/dotfiles/setup`) had an issue where **chezmoi** was not available after installation, causing shell configuration files to not be applied.

### Root Cause

1. The chezmoi installer script (`get.chezmoi.io`) installs the binary to `~/bin/chezmoi` or `~/.local/bin/chezmoi`
2. The setup script expected chezmoi to be in the user's PATH immediately
3. Since `~/bin` was not in the PATH during script execution, chezmoi couldn't be found
4. Same issue affected mise installation

### Symptoms

```bash
⚠️  Chezmoi not found in PATH after installation.
    Skipping shell config application. Please run manually:
    export PATH="$HOME/bin:$PATH"
    chezmoi init --source="/root/dotfiles"
    chezmoi apply
```

## Solution Implemented

### 1. Added `install_system_tool()` Function

Created a new function that:
- Installs tools (chezmoi, mise) to **`/usr/local/bin`** (system-wide location)
- Makes tools available for **all users** (root and non-root)
- Eliminates PATH issues during installation
- Provides consistent tool availability

### 2. System-Wide Installation Locations

```bash
# Now installed here (available to all users):
/usr/local/bin/chezmoi  (35MB)
/usr/local/bin/mise     (62MB)

# Previously installed here (user-specific):
~/bin/chezmoi
~/.local/bin/mise
```

### 3. Simplified Setup Logic

**Before:**
- Install to user directory
- Export PATH for current session
- Hope the tool is found later
- Multiple conditional checks

**After:**
- Install directly to system location
- Tool immediately available in standard PATH
- No PATH manipulation needed
- Clean and predictable

## Changes Made

### Modified: `~/dotfiles/setup`

```bash
# Added at the beginning of script:
install_system_tool() {
  local tool_name="$1"
  local install_command="$2"

  # Installs to user location first, then copies to /usr/local/bin
  # Makes tools available system-wide
}

# Call for both tools:
install_system_tool "chezmoi" 'sh -c "$(curl -fsLS get.chezmoi.io)"'
install_system_tool "mise" 'curl https://mise.run | sh'
```

### Removed

- User-specific PATH exports during installation
- Conditional checks for chezmoi availability
- Warning messages about missing tools

## Verification

```bash
# Check installations:
$ which chezmoi
/usr/local/bin/chezmoi

$ which mise
/usr/local/bin/mise

$ chezmoi --version
chezmoi version v2.67.0

$ mise --version
2025.11.1 linux-x64

# Verify system-wide availability:
$ sudo -u otheruser which chezmoi
/usr/local/bin/chezmoi  # ✓ Available to all users
```

## Testing

The updated script was tested successfully:

```bash
$ cd ~/dotfiles && ./setup

🚀 Setting up dotfiles...
📦 Installing chezmoi system-wide...
✅ chezmoi installed to /usr/local/bin (available for all users)
✅ mise already installed
📝 Applying shell configuration files...
💾 Backed up existing .zshrc to ~/2025-11-03_.zshrc_backup
✅ Applied .zshrc from dotfiles
🎉 Dotfiles setup complete!
```

## Benefits

1. **Reliability**: Tools are guaranteed to be in PATH
2. **Consistency**: Same behavior for all users
3. **Simplicity**: No PATH manipulation needed
4. **Standards**: Uses standard `/usr/local/bin` location
5. **No Surprises**: Works the same way every time

## Next Steps for Users

After pulling the updated dotfiles:

```bash
cd ~/dotfiles
./setup  # Will now work correctly

# Optionally apply remaining configs:
chezmoi diff          # Preview changes
chezmoi apply         # Apply all configs
```

## Commit Details

**Repository**: https://github.com/alexbenisch/dotfiles
**Commit**: a99a08e
**Branch**: main

**Commit Message**:
```
Add system-wide installation for chezmoi and mise

- Add install_system_tool() function to install tools to /usr/local/bin
- Makes chezmoi and mise available for all users (root and non-root)
- Removes user-specific PATH workarounds
- Fixes issue where chezmoi wasn't found after installation
- Simplifies setup script by centralizing tool installation logic
```
