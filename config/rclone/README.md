# rclone Configuration for Cave (WebDAV Storage)

This directory contains the configuration for automatically mounting the Cave WebDAV server to `~/Cave` using rclone, providing a Dropbox-like experience with local caching and background sync.

## Overview

- **Remote**: WebDAV server at `https://cave.yoaquim.com/`
- **Mount Point**: `~/Cave`
- **Cache Mode**: Full VFS caching (editable locally, syncs to server)
- **Cache Size**: 50GB max
- **Auto-start**: Via macOS LaunchAgent on login

## Setup Instructions

### 1. Add WebDAV Credentials to bash_profile_local

WebDAV credentials are stored as environment variables in `~/.config/bash/bash_profile_local` (which is already git-ignored).

Add these lines to `~/.config/bash/bash_profile_local`:

```bash
# WebDAV credentials for Cave (rclone mount)
# Password must be obscured using: rclone obscure "your-plaintext-password"
export CAVE_WEBDAV_USER="your-username-here"
export CAVE_WEBDAV_PASS="your-obscured-password-here"
```

**Important**: The password must be obscured (encrypted) using rclone:
```bash
rclone obscure "your-actual-password"
# Copy the output and use it as CAVE_WEBDAV_PASS
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
- Create symlink: `~/.config/rclone/` -> `~/.dotfiles/config/rclone/`
- Create symlink: `~/Library/LaunchAgents/com.rclone.cave.plist` -> dotfiles
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

1. **Store**: WebDAV credentials in `~/.config/bash/bash_profile_local` as `CAVE_WEBDAV_*` variables
2. **Load**: `mount-cave.sh` sources `bash_profile_local` on startup
3. **Export**: Script exports `RCLONE_WEBDAV_USER` and `RCLONE_WEBDAV_PASS` from `CAVE_WEBDAV_*`
4. **Use**: rclone reads these environment variables for authentication

This approach keeps credentials:
- Out of git (bash_profile_local is git-ignored)
- Secure (only in memory, not in config files)
- Portable (same pattern for all machines)

### VFS Caching Explained

The mount uses `--vfs-cache-mode full`, which provides:

1. **Immediate local writes**: Files are written to local cache first
2. **Background sync**: Changes sync to server in the background (5s delay)
3. **Fast reads**: Frequently accessed files are cached locally
4. **Offline editing**: Edit files even if server is temporarily unavailable

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
├── rclone.conf                    # Config (no secrets, safe to commit)
├── mount-cave.sh                  # Mount script (loads credentials)
├── com.rclone.cave.plist          # LaunchAgent definition
└── README.md                      # This file

~/.dotfiles/config/bash/
└── bash_profile_local             # WebDAV credentials stored here (NOT in git)

~/.config/rclone/                  # Symlink -> ~/.dotfiles/config/rclone/
~/.cache/rclone/
├── vfs/                           # VFS cache directory (up to 50GB)
├── cave.log                       # rclone mount log
├── cave-stdout.log                # LaunchAgent stdout
└── cave-stderr.log                # LaunchAgent stderr

~/Cave/                            # Mount point
~/Library/LaunchAgents/
└── com.rclone.cave.plist          # Symlink -> dotfiles
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

1. **Check WebDAV credentials are set**:
   ```bash
   # Check if variables are exported
   echo $CAVE_WEBDAV_USER
   echo $CAVE_WEBDAV_PASS

   # If empty, add them to ~/.config/bash/bash_profile_local:
   export CAVE_WEBDAV_USER="your-username"
   export CAVE_WEBDAV_PASS="your-password"

   # Then reload
   source ~/.bash_profile
   ```

2. Check rclone configuration:
   ```bash
   rclone config show cave
   ```

3. Test WebDAV connection:
   ```bash
   rclone lsd cave: --webdav-user="$CAVE_WEBDAV_USER" --webdav-pass="$CAVE_WEBDAV_PASS"
   ```

4. Test mount manually (will show errors if any):
   ```bash
   ~/.dotfiles/config/rclone/mount-cave.sh
   ```

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

- WebDAV credentials are stored in `~/.config/bash/bash_profile_local` as environment variables
- `bash_profile_local` is excluded from git (machine-specific config)
- Never commit or share files containing `CAVE_WEBDAV_USER` or `CAVE_WEBDAV_PASS`
- `rclone.conf` contains **no secrets** - safe to commit to git
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
- [rclone WebDAV backend](https://rclone.org/webdav/)
- [rclone mount documentation](https://rclone.org/commands/rclone_mount/)
- [VFS cache modes](https://rclone.org/commands/rclone_mount/#vfs-cache-mode)
