# Waybar Configuration

## Overview
[Waybar](https://github.com/Alexays/Waybar) is a highly customizable status bar for Wayland compositors like Hyprland. This configuration provides a modern, informative status bar with a clean design.

## Features
- **Workspace Display**: Shows Hyprland workspaces with visual indicators
- **System Information**: Battery, network, audio, and system tray
- **Date/Time**: Formatted clock with calendar tooltip
- **Modern Theme**: Clean design with subtle animations
- **Interactive Elements**: Clickable modules for quick access

## Layout

### Left Section
- **Workspaces**: Current workspace indicator with navigation
- **Submap**: Mode indicator (when in special Hyprland modes)

### Center Section  
- **Clock**: Date and time display with calendar tooltip

### Right Section
- **System Tray**: Application status icons
- **Network**: Wi-Fi/Ethernet connection status
- **Battery**: Charge level and status (laptops)
- **Audio**: Volume control and device indicator
- **Power**: Quick access to power menu

## Modules Configuration

### Workspaces
- Displays workspaces 1-10
- Visual indicators for active/focused workspace
- Urgent workspace highlighting
- Scroll wheel navigation disabled for stability

### Clock
- Format: `Day DD Mon  HH:MM AM/PM`
- Timezone aware
- Calendar popup on hover
- Alternative format available

### Battery (laptops)
- Shows percentage and charging status
- Color-coded warnings (30% and 15%)
- Animated critical battery indicator
- Displays time remaining when available

### Network
- Shows SSID and signal strength for Wi-Fi
- IP address display for Ethernet
- Right-click opens network manager
- Clear disconnection indicators

### Audio
- Volume percentage and device icon
- Bluetooth device support
- Mute state indication
- Click to open volume control
- Right-click to toggle mute

## Theme Colors

### Base Colors
- **Background**: `rgba(43, 48, 59, 0.95)` - Semi-transparent dark
- **Text**: `#ffffff` - White for contrast
- **Accent**: `#64727D` - Muted blue-gray

### Module Colors
- **Active Workspace**: White border and background
- **Battery**: White (normal), Green (charging), Red (critical)
- **Network**: Blue (connected), Red (disconnected)  
- **Audio**: Yellow (active), Gray (muted)
- **Power**: Red with darker hover state

## Dependencies
- `waybar` - The status bar application
- `pavucontrol` - Audio control (optional)
- `network-manager-applet` - Network management (optional)
- Font: `JetBrainsMono Nerd Font Mono`

## Installation Location
- **Config**: `~/.config/waybar/config` (symlinked from dotfiles)
- **Style**: `~/.config/waybar/style.css` (symlinked from dotfiles)

## Customization

### Adding Modules
Edit `config` to add modules like:
- `cpu` - CPU usage
- `memory` - RAM usage  
- `temperature` - System temperature
- `disk` - Disk usage
- `custom/*` - Custom scripts

### Styling Changes
Edit `style.css` to modify:
- Colors and transparency
- Font sizes and families
- Animation speeds
- Spacing and padding
- Border styles

### Module Settings
Each module can be configured with:
- Custom formats and icons
- Update intervals
- Click actions
- Tooltip content

## Integration
Works seamlessly with:
- **Hyprland**: Workspace and window information
- **PulseAudio/PipeWire**: Audio control
- **NetworkManager**: Network status
- **System tray**: Application notifications
- **rofi**: Power menu integration

## Troubleshooting
- Check waybar logs: `journalctl --user -u waybar.service`
- Test configuration: `waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css`
- Reload waybar: `killall waybar && waybar &`

## Alternative Configurations
The config can be easily modified for different layouts:
- Bottom bar placement
- Different module arrangements  
- Alternative color schemes
- Minimalist or information-dense layouts