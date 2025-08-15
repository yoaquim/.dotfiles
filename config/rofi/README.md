# Rofi Configuration

## Overview
[Rofi](https://github.com/davatorium/rofi) is a window switcher, application launcher and dmenu replacement for Linux. This configuration provides an Alfred-like experience with fast fuzzy search for applications, files, and system functions.

## Features
- **Application Launcher**: Fast fuzzy search through installed applications
- **File Browser**: Navigate and launch files from the filesystem  
- **Run Dialog**: Execute arbitrary commands
- **SSH Launcher**: Quick SSH connections
- **Power Menu**: System power management options
- **Modern Theme**: Clean, Alfred-inspired design with icons

## Usage

### Basic Launching
- **Apps**: `rofi -show drun` or `Super + Space` (via Hyprland config)
- **Files**: `rofi -show filebrowser`
- **Commands**: `rofi -show run`
- **SSH**: `rofi -show ssh`
- **Power Menu**: Custom script via waybar power button

### Search Features
- **Fuzzy Matching**: Type partial names, e.g., "firef" matches "Firefox"
- **Category Search**: Applications grouped by type
- **Recent Items**: Previously used items appear first
- **Keyword Search**: Search by application keywords and descriptions

### Navigation
- **Arrow Keys**: Navigate up/down through results
- **Tab**: Switch between modes (drun/run/filebrowser/ssh)
- **Enter**: Launch selected item
- **Escape**: Cancel/close
- **Ctrl+J/K**: Navigate with vim-style keys

## Configuration Structure

### Main Config (`config.rasi`)
- **Appearance**: Window size, positioning, fonts
- **Behavior**: Search modes, fuzzy matching, icons
- **Keybindings**: Navigation and action shortcuts
- **Theme**: Colors, transparency, visual effects

### Power Menu Script
- **Lock**: Activate screen lock (swaylock-effects)
- **Logout**: Exit Hyprland session
- **Suspend**: System suspend
- **Shutdown**: Power off system
- **Reboot**: Restart system

## Theme Design

### Alfred-Inspired Layout
- **Centered Window**: 600px wide, clean positioning
- **Search Bar**: Prominent input field with placeholder text
- **Results List**: Clean list with icons and descriptions
- **Rounded Corners**: Modern visual appearance
- **Transparency**: Subtle background blur effect

### Color Scheme
- **Background**: Semi-transparent dark blue (`rgba(0, 43, 54, 95%)`)
- **Text**: Light gray for readability
- **Selection**: Blue highlight (`rgba(38, 139, 210, 100%)`)
- **Border**: Blue accent matching Hyprland theme
- **Icons**: Papirus-Dark icon theme integration

## Customization

### Adding Custom Modi
Edit `config.rasi` to add new modes:
```rasi
modi: "drun,run,filebrowser,ssh,window,calc";
```

### Keyboard Shortcuts
Modify keybindings section:
```rasi
kb-row-up: "Up,Control+p,ISO_Left_Tab";
kb-row-down: "Down,Control+n";
kb-accept-entry: "Control+j,Control+m,Return,KP_Enter";
```

### Visual Appearance
Adjust theme colors and sizing:
```rasi
window {
    width: 800;        /* Wider window */
    border-radius: 15; /* More rounded corners */
}
```

### File Browser Settings
Configure file browser behavior:
```rasi
filebrowser {
    directories-first: true;
    sorting-method: "name";
}
```

## Integration

### Hyprland Integration
- Bound to `Super + Space` in Hyprland config
- Power menu integration via waybar
- Screenshot and system shortcuts available

### Application Detection
- Uses `.desktop` files for application discovery
- Supports Flatpak and system packages
- Icon theme integration (Papirus-Dark)
- Categories and keywords for better search

### Terminal Integration
- Uses `kitty` as default terminal
- SSH connections open in new terminal windows
- Command execution with terminal fallback

## Advanced Features

### Custom Scripts
Create custom rofi modi in `~/.config/rofi/scripts/`:
```bash
#!/bin/bash
# Custom calculator script
echo -e "2+2\n5*5\n10/2" | rofi -dmenu -p "calc"
```

### Dynamic Menus
Build dynamic content:
```bash
# Recent files menu
find ~ -type f -name "*.pdf" -printf '%T@ %p\n' | \
  sort -k 1 -nr | head -10 | \
  cut -d' ' -f2- | \
  rofi -dmenu -p "Recent PDFs"
```

## Dependencies
- `rofi-wayland` - Wayland-compatible rofi build
- `papirus-icon-theme` - Icon theme
- `JetBrainsMono Nerd Font` - Font family
- `swaylock-effects` - For lock screen function
- `systemd` - For power management functions

## Troubleshooting
- **No icons**: Install `papirus-icon-theme` and verify icon-theme setting
- **Slow search**: Check if file indexing is enabled
- **Wrong terminal**: Verify `terminal: "kitty"` setting
- **Power menu fails**: Ensure power menu script is executable
- **Theme issues**: Check theme file syntax with `rofi -dump-theme`

## Performance Tips
- **Disable unused modi**: Remove unused search modes
- **Limit file browser depth**: Set reasonable directory limits
- **Cache optimization**: Enable application cache for faster startup