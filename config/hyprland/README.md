# Hyprland Configuration

## Overview
[Hyprland](https://hyprland.org) is a highly customizable dynamic tiling Wayland compositor that doesn't sacrifice on its looks. This configuration provides a modern, efficient desktop environment for Linux systems.

## Features
- **Tiling Window Management**: Automatic window arrangement with manual override capability
- **Modern Animations**: Smooth transitions and effects
- **Multi-Monitor Support**: Flexible monitor configuration
- **Keyboard-Driven Workflow**: Extensive keybindings for productivity
- **Integration**: Works seamlessly with waybar, rofi, and other Wayland tools

## Key Bindings

### Basic Navigation
| Key Combination | Action |
|---|---|
| `Super + Return` | Open terminal (kitty) |
| `Super + Q` | Close active window |
| `Super + Shift + Q` | Exit Hyprland |
| `Super + Space` | App launcher (rofi) |
| `Super + L` | Lock screen |

### Window Management
| Key Combination | Action |
|---|---|
| `Super + h/j/k/l` | Move focus (vim-style) |
| `Super + Shift + h/j/k/l` | Move windows |
| `Super + V` | Toggle floating mode |
| `Super + P` | Toggle pseudotile |
| `Super + J` | Toggle split |

### Workspaces
| Key Combination | Action |
|---|---|
| `Super + 1-9,0` | Switch to workspace |
| `Super + Shift + 1-9,0` | Move window to workspace |
| `Super + S` | Toggle special workspace (scratchpad) |
| `Super + Mouse Scroll` | Cycle workspaces |

### System Controls
| Key Combination | Action |
|---|---|
| `Print` | Screenshot (full screen) |
| `Super + Print` | Screenshot (selection) |
| `XF86AudioRaise/LowerVolume` | Volume control |
| `XF86MonBrightnessUp/Down` | Brightness control |

## Layout
Uses the **dwindle** layout by default, which provides:
- Automatic tiling with intelligent placement
- Pseudotiling support for better floating window handling
- Split preservation for consistent layouts

## Theming
- **Gaps**: 5px inner, 10px outer
- **Borders**: 2px with gradient active border
- **Rounded Corners**: 5px radius
- **Blur Effects**: Enabled with subtle vibrancy
- **Shadows**: Soft drop shadows for depth

## Configuration Location
- **System**: `~/.config/hypr/hyprland.conf` (symlinked from dotfiles)
- **Logs**: `~/.hyprland.log`

## Dependencies
- `hyprland` - The compositor
- `kitty` - Terminal emulator
- `waybar` - Status bar
- `rofi-wayland` - Application launcher
- `swaylock-effects` - Screen locker
- `hyprpaper` - Wallpaper utility
- `variety` - Wallpaper management
- `swhkd` - Global hotkey daemon
- `wl-clipboard` - Clipboard utilities
- `grim` + `slurp` - Screenshot tools

## Autostart Programs
The configuration automatically starts:
- waybar (status bar)
- hyprpaper (wallpaper)
- variety (wallpaper rotation)
- swayidle (idle management)
- swhkd (hotkey daemon)

## Customization
Edit `~/.config/hypr/hyprland.conf` to customize:
- Key bindings
- Window rules
- Animations
- Colors and theming
- Monitor configuration

## Troubleshooting
- Check logs: `journalctl --user -u hyprland.service`
- Test configuration: `hyprctl reload`
- Debug mode: Start with `Hyprland -d`

## Integration with Dotfiles
This configuration integrates with:
- **bash**: Same shell environment and aliases
- **tmux**: Works in terminals, window management via Hyprland
- **kitty**: Terminal emulator configuration
- **neovim**: Editor remains identical
- **git**: All git aliases and functions preserved