# rclone Configuration for Cave (S3 Storage)

This directory contains the configuration for automatically mounting the `terra-cave-us-east-1` S3 bucket to `~/Cave` using rclone and macFUSE, providing a Dropbox-like experience with local caching and background sync.

## Overview

- **Remote**: S3 bucket `terra-cave-us-east-1` in `us-east-1`
- **Mount Point**: `~/Cave`
- **Cache Mode**: Full VFS caching (editable locally, syncs to S3)
- **Cache Size**: 50GB max
- **Auto-start**: Via macOS LaunchAgent on login

## Setup Instructions

### 1. Add AWS Credentials to bash_profile_local

AWS credentials are stored as environment variables in `~/.config/bash/bash_profile_local` (which is already git-ignored).

Add these lines to `~/.config/bash/bash_profile_local`:

```bash
# AWS credentials for Cave (rclone S3 mount)
export CAVE_AWS_ACCESS_KEY_ID="your-access-key-id-here"
export CAVE_AWS_SECRET_ACCESS_KEY="your-secret-access-key-here"
```

Then reload your shell:

```bash
source ~/.bash_profile
```

**Why `bash_profile_local`?**
- Already git-ignored (machine-specific config)
- Follows existing dotfiles pattern
- Credentials loaded in all shell sessions
- No plaintext credentials in rclone.conf

### 2. Run the Installer

```bash
cd ~/.dotfiles
./install.sh
```

The installer will:
- Create symlink: `~/.config/rclone/` → `~/.dotfiles/config/rclone/`
- Create symlink: `~/Library/LaunchAgents/com.rclone.cave.plist` → dotfiles
- Create `~/Cave` mount point directory
- Set up the LaunchAgent for auto-start
- Check if credentials are configured and remind you if not

### Start the Mount

The installer automatically loads the LaunchAgent if credentials are configured.

If you need to manually load it (without `sudo`!):

```bash
launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist
```

**Important**: Do NOT use `sudo` - LaunchAgents run as your user, not root.

After a few seconds, `~/Cave` should be mounted and accessible.

## Usage

### Opening Cave

Use the `cave` bash command (alias):

```bash
cave
```

This opens `~/Cave` in Finder if mounted, or shows mount status if not.

### Manual Control

**Start/Mount:**
```bash
launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist
```

**Stop/Unmount:**
```bash
launchctl unload ~/Library/LaunchAgents/com.rclone.cave.plist
umount ~/Cave  # If needed
```

**Check Status:**
```bash
launchctl list | grep rclone
mount | grep Cave
```

**Restart:**
```bash
launchctl unload ~/Library/LaunchAgents/com.rclone.cave.plist
sleep 2
launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist
```

## How It Works

### Credential Flow

1. **Store**: AWS credentials in `~/.config/bash/bash_profile_local` as `CAVE_AWS_*` variables
2. **Load**: `mount-cave.sh` sources `bash_profile_local` on startup
3. **Export**: Script exports `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from `CAVE_AWS_*`
4. **Use**: rclone reads standard AWS environment variables (via `env_auth = true`)

This approach keeps credentials:
- Out of git (bash_profile_local is git-ignored)
- Secure (only in memory, not in config files)
- Portable (same pattern for all machines)

### VFS Caching Explained

The mount uses `--vfs-cache-mode full`, which provides:

1. **Immediate local writes**: Files are written to local cache first
2. **Background sync**: Changes sync to S3 in the background (5s delay)
3. **Fast reads**: Frequently accessed files are cached locally
4. **Offline editing**: Edit files even if S3 is temporarily unavailable

### Cache Settings

```bash
--vfs-cache-mode full          # Full local caching with background sync
--vfs-cache-max-size 50G       # Maximum 50GB local cache
--vfs-cache-max-age 168h       # Keep cached files for 1 week
--vfs-write-back 5s            # Wait 5s before uploading changes
--vfs-read-ahead 128M          # Pre-fetch 128MB when reading files
--buffer-size 64M              # 64MB buffer for transfers
--dir-cache-time 5m            # Cache directory listings for 5 minutes
--poll-interval 15s            # Check for remote changes every 15s
```

### Files and Locations

```
~/.dotfiles/config/rclone/
├── rclone.conf                    # Config (uses env_auth, safe to commit)
├── mount-cave.sh                  # Mount script (loads credentials)
├── com.rclone.cave.plist          # LaunchAgent definition
└── README.md                      # This file

~/.dotfiles/config/bash/
└── bash_profile_local             # AWS credentials stored here (NOT in git)

~/.config/rclone/                  # Symlink → ~/.dotfiles/config/rclone/
~/.cache/rclone/
├── vfs/                           # VFS cache directory (up to 50GB)
├── cave.log                       # rclone mount log
├── cave-stdout.log                # LaunchAgent stdout
└── cave-stderr.log                # LaunchAgent stderr

~/Cave/                            # Mount point
~/Library/LaunchAgents/
└── com.rclone.cave.plist          # Symlink → dotfiles
```

## Troubleshooting

### Check if Cave is mounted

```bash
mount | grep Cave
ls -la ~/Cave
```

### View logs

```bash
# rclone mount log
tail -f ~/.cache/rclone/cave.log

# LaunchAgent logs
tail -f ~/.cache/rclone/cave-stdout.log
tail -f ~/.cache/rclone/cave-stderr.log

# LaunchAgent status
launchctl list | grep rclone
```

### Mount not starting

1. **Check AWS credentials are set**:
   ```bash
   # Check if variables are exported
   echo $CAVE_AWS_ACCESS_KEY_ID
   echo $CAVE_AWS_SECRET_ACCESS_KEY

   # If empty, add them to ~/.config/bash/bash_profile_local:
   export CAVE_AWS_ACCESS_KEY_ID="your-key"
   export CAVE_AWS_SECRET_ACCESS_KEY="your-secret"

   # Then reload
   source ~/.bash_profile
   ```

2. Check if macFUSE is installed:
   ```bash
   brew list --cask | grep macfuse
   ```

3. Check rclone configuration:
   ```bash
   rclone config show cave
   ```

4. Test mount manually (will show credential errors if any):
   ```bash
   ~/.dotfiles/config/rclone/mount-cave.sh
   ```

### Permission errors

macFUSE requires system extension approval on first use:
1. Open **System Settings** → **Privacy & Security**
2. Look for blocked system extension from "Benjamin Fleischer"
3. Click **Allow** and restart

### Cache full

If the 50GB cache fills up, rclone will automatically remove least-recently-used files. To manually clear cache:

```bash
# Stop mount first
launchctl unload ~/Library/LaunchAgents/com.rclone.cave.plist

# Clear cache
rm -rf ~/.cache/rclone/vfs/*

# Restart mount
launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist
```

### Verify S3 connection

Test rclone can access S3:

```bash
rclone ls cave:terra-cave-us-east-1 --max-depth 1
```

### Force unmount

If normal unmount fails:

```bash
umount -f ~/Cave
# or
diskutil unmount force ~/Cave
```

## Performance Tips

1. **Keep frequently used files in cache**: Access them regularly to prevent eviction
2. **Large file uploads**: May take time to complete in background (check logs)
3. **Network interruptions**: Files remain accessible from cache; sync resumes automatically
4. **First access**: Files not in cache will download on first access (may be slow)

## Security Notes

- AWS credentials are stored in `~/.config/bash/bash_profile_local` as environment variables
- `bash_profile_local` is excluded from git (machine-specific config)
- Never commit or share files containing `CAVE_AWS_ACCESS_KEY_ID` or `CAVE_AWS_SECRET_ACCESS_KEY`
- `rclone.conf` uses `env_auth = true` and contains **no secrets** - safe to commit to git
- All files in `config/rclone/` can be safely committed

## Uninstalling

To remove the Cave mount:

```bash
# Stop and remove LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.rclone.cave.plist
rm ~/Library/LaunchAgents/com.rclone.cave.plist

# Remove symlink
rm ~/.config/rclone

# Optionally remove cache
rm -rf ~/.cache/rclone

# Optionally remove mount point (after backing up!)
rm -rf ~/Cave
```

## References

- [rclone documentation](https://rclone.org/docs/)
- [rclone mount documentation](https://rclone.org/commands/rclone_mount/)
- [VFS cache modes](https://rclone.org/commands/rclone_mount/#vfs-cache-mode)
- [macFUSE](https://osxfuse.github.io/)
