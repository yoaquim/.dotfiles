# swhkd Configuration

## Overview
[swhkd](https://github.com/waycrate/swhkd) is a Simple Wayland HotKey Daemon that serves as a drop-in replacement for sxhkd and provides Hammerspoon-like functionality for Linux. It's display protocol-independent and works on Wayland, X11, and TTY.

## Features
- **Global Hotkeys**: System-wide keyboard shortcuts
- **Hyprland Integration**: Window management controls
- **Application Launching**: Quick access to frequently used apps
- **Media Controls**: Volume, brightness, and media player shortcuts
- **Wallpaper Management**: Variety integration for wallpaper control
- **Development Tools**: Quick terminal and editor shortcuts

## Installation
swhkd needs to be built from source as it's not available as a pre-built package:

```bash
# Install dependencies
sudo dnf install rust cargo make git polkit-devel scdoc

# Clone and build
git clone https://github.com/waycrate/swhkd.git
cd swhkd
make build
sudo make install
```

## Key Bindings Reference

### Application Shortcuts
| Key Combination | Action |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + Space` | App launcher (rofi) |
| `Super + E` | File manager |
| `Super + W` | Web browser (Firefox) |
| `Super + V` | Text editor (neovim) |
| `Super + C` | VS Code |

### System Controls
| Key Combination | Action |
|---|---|
| `Super + L` | Lock screen |
| `Super + Shift + Q` | Power menu |
| `Super + Ctrl + R` | Restart waybar |
| `Print` | Screenshot (full screen) |
| `Super + Print` | Screenshot (selection) |

### Window Management
| Key Combination | Action |
|---|---|
| `Super + Q` | Close active window |
| `Super + Shift + V` | Toggle floating |
| `Super + F` | Toggle fullscreen |
| `Super + H/J/K/L` | Move focus (vim-style) |
| `Super + Shift + H/J/K/L` | Move windows |
| `Super + Ctrl + H/J/K/L` | Resize windows |

### Workspace Management
| Key Combination | Action |
|---|---|
| `Super + 1-9,0` | Switch to workspace |
| `Super + Shift + 1-9,0` | Move window to workspace |
| `Super + S` | Toggle special workspace |
| `Super + Shift + S` | Move to special workspace |

### Media Controls
| Key Combination | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioPlay` | Play/pause media |
| `XF86AudioNext/Prev` | Next/previous track |

### Brightness
| Key Combination | Action |
|---|---|
| `XF86MonBrightnessUp` | Increase brightness |
| `XF86MonBrightnessDown` | Decrease brightness |

### Wallpaper Controls
| Key Combination | Action |
|---|---|
| `Super + Alt + N` | Next wallpaper |
| `Super + Alt + P` | Previous wallpaper |
| `Super + Alt + F` | Favorite wallpaper |
| `Super + Alt + T` | Trash wallpaper |

### Development Shortcuts
| Key Combination | Action |
|---|---|
| `Super + Alt + Return` | Terminal in home directory |
| `Super + Shift + Return` | Terminal in current directory |
| `Super + Shift + V` | Open nvim in current directory |
| `Super + G` | Show git status |

## Configuration Structure

### Main Config File
- **Location**: `/etc/swhkd/swhkdrc` (system) or symlink from dotfiles
- **Format**: Similar to sxhkd syntax
- **Comments**: Lines starting with `#`
- **Key Syntax**: `modifier + key`

### Key Modifiers
- `super` - Windows/Cmd key
- `alt` - Alt key
- `ctrl` - Control key
- `shift` - Shift key
- Multiple modifiers: `super + shift + key`

### Special Keys
- Function keys: `F1`, `F2`, etc.
- Media keys: `XF86AudioRaiseVolume`, `XF86MonBrightnessUp`, etc.
- Navigation: `Up`, `Down`, `Left`, `Right`
- System: `Print`, `Return`, `space`, `Escape`

## Integration with Hyprland

### Window Management Commands
All window management shortcuts use `hyprctl dispatch` commands:
- `killactive` - Close window
- `togglefloating` - Toggle floating mode
- `fullscreen` - Toggle fullscreen
- `movefocus [direction]` - Move focus
- `movewindow [direction]` - Move window
- `resizeactive [x] [y]` - Resize window

### Workspace Commands
- `workspace [number]` - Switch workspace
- `movetoworkspace [number]` - Move window to workspace
- `togglespecialworkspace [name]` - Toggle special workspace

## Security Model

### Server-Client Architecture
- **swhkd** (daemon): Privileged process listening to key events
- **swhks** (server): Non-privileged process managing environment
- Commands parsed from config file only
- No arbitrary shell command execution

### Permissions
- Requires polkit privileges for global key listening
- Config file must be readable by swhkd user
- Commands run with user privileges, not root

## Customization

### Adding Custom Shortcuts
Edit the config file to add new shortcuts:
```bash
# Custom application
super + shift + b
    brave-browser

# Custom script
super + alt + s
    ~/scripts/system-info.sh
```

### Conditional Commands
Use shell logic for complex commands:
```bash
# Different behavior based on conditions
super + t
    if [ -n "$TMUX" ]; then tmux new-window; else kitty; fi
```

### Application-Specific Shortcuts
Create shortcuts for specific applications:
```bash
# Only in terminal applications
super + ctrl + t
    if [ "$TERM" ]; then tmux; fi
```

## Troubleshooting

### Common Issues
1. **Keys not working**: Check if swhkd daemon is running
2. **Permission denied**: Ensure polkit configuration is correct
3. **Config not loading**: Verify config file path and syntax
4. **Hyprctl commands fail**: Ensure Hyprland is running

### Debugging
- Check daemon status: `systemctl --user status swhkd`
- View logs: `journalctl --user -u swhkd`
- Test config: Kill daemon and run manually
- Verify permissions: Check polkit rules

### Service Management
```bash
# Enable service
systemctl --user enable swhkd

# Start/stop service
systemctl --user start swhkd
systemctl --user stop swhkd

# Reload config
systemctl --user reload swhkd
```

## Dependencies
- `swhkd` - The hotkey daemon (built from source)
- `polkit` - Permission management
- `hyprctl` - Hyprland control (if using Hyprland features)
- `wpctl` / `pulseaudio` - Audio control
- `brightnessctl` - Brightness control
- `playerctl` - Media control
- `variety` - Wallpaper management
- Various applications as referenced in shortcuts

## Performance Notes
- Minimal resource usage
- Fast key response time
- Works in any environment (TTY, X11, Wayland)
- No GUI dependency
- Efficient config parsing