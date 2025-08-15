# Swaylock Configuration

## Overview
[Swaylock-effects](https://github.com/mortie/swaylock-effects) is an enhanced fork of swaylock (the screen locker for Wayland) with additional visual effects and customization options. It provides a secure, modern lock screen experience for Hyprland and other Wayland compositors.

## Features
- **Visual Effects**: Blur, pixelate, scale, vignette effects
- **Customizable Appearance**: Colors, fonts, layout options
- **Clock Display**: Time and date on lock screen
- **Security**: Proper screen locking with grace period
- **Multi-Monitor**: Works across multiple displays
- **Keyboard Layout**: Shows current keyboard layout

## Installation
Install via COPR repository (handled by install script):
```bash
sudo dnf copr enable eddsalkield/swaylock-effects
sudo dnf install swaylock-effects
```

## Configuration

### Location
- **Config File**: `~/.config/swaylock/config`
- **Global Config**: `/etc/swaylock/config` (system-wide)

### Visual Effects

#### Blur Effect
```conf
effect-blur=7x5          # Blur radius and passes
```

#### Alternative Effects
```conf
effect-pixelate=5        # Pixelation size
effect-scale=0.5         # Scale factor
effect-vignette=0.5:0.5  # Vignette intensity
effect-greyscale         # Convert to grayscale
```

#### Fade Transition
```conf
fade-in=0.2              # Fade-in duration in seconds
```

### Color Scheme

#### Background
```conf
color=00000080           # Semi-transparent black background
```

#### Ring Colors (password input indicator)
- `ring-color` - Default ring color
- `ring-clear-color` - Ring when clearing input
- `ring-caps-lock-color` - Ring when caps lock is on
- `ring-ver-color` - Ring during verification
- `ring-wrong-color` - Ring after wrong password

#### Text Colors
All text elements can be customized:
- `text-color` - Default text
- `text-clear-color` - Text when clearing
- `text-ver-color` - Text during verification
- `text-wrong-color` - Text after wrong password

### Clock Configuration
```conf
clock                    # Enable clock display
timestr=%I:%M %p        # Time format (12-hour with AM/PM)
datestr=%A, %B %e       # Date format (Day, Month Date)
font=JetBrainsMono Nerd Font Mono
font-size=16
```

### Behavior Settings
```conf
show-failed-attempts     # Display failed login count
show-keyboard-layout     # Show current keyboard layout
screen-off-timeout=300   # Turn off screen after 5 minutes
grace=2                 # Grace period before lock activates
ignore-empty-password   # Don't count empty password attempts
```

## Usage

### Manual Locking
```bash
# Basic lock
swaylock-effects

# Lock with custom config
swaylock-effects -C ~/.config/swaylock/config

# Lock with specific effect
swaylock-effects --effect-blur=10x3
```

### Integration with Hyprland
Bound to `Super + L` in Hyprland and swhkd configurations:
```conf
# In hyprland.conf
bind = $mainMod, L, exec, swaylock-effects

# In swhkdrc  
super + l
    swaylock-effects
```

### Automatic Locking with swayidle
```bash
# In Hyprland autostart
exec-once = swayidle -w timeout 300 'swaylock-effects' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'
```

## Customization Examples

### Minimal Clean Look
```conf
color=000000cc
effect-blur=7x5
ring-color=ffffff60
text-color=ffffff
inside-color=00000000
fade-in=0.3
clock
```

### Colorful Theme
```conf
color=2c3e5099
effect-blur=5x3
ring-color=3498db80
ring-ver-color=2ecc7180
ring-wrong-color=e74c3c80
text-color=ecf0f1
clock
datestr=%A, %B %e
timestr=%H:%M
```

### High Security Mode
```conf
color=000000ff
no-unlock-indicator
disable-caps-lock-text
ignore-empty-password
screen-off-timeout=120
grace=0
```

### Background Image
```conf
image=~/.config/swaylock/background.jpg
scaling=fill
effect-blur=3x2
color=00000040  # Overlay color
```

## Security Features

### Password Handling
- Secure password input (not stored in memory)
- Configurable grace period
- Failed attempt tracking
- Empty password handling

### Screen Management
- Screen off timeout for privacy
- Multi-monitor support
- Prevents screen recording during lock
- Keyboard layout display

### Integration Security
- PAM authentication
- Privilege dropping
- Signal handling
- Wayland security protocols

## Troubleshooting

### Common Issues

#### Lock Screen Not Appearing
```bash
# Check if swaylock-effects is installed
which swaylock-effects

# Test basic functionality
swaylock-effects --help

# Check Wayland permissions
echo $WAYLAND_DISPLAY
```

#### Visual Effects Not Working
```bash
# Check compositor support
# Ensure running on Wayland
echo $XDG_SESSION_TYPE

# Test without effects
swaylock-effects --color=000000
```

#### Authentication Problems
```bash
# Check PAM configuration
ls /etc/pam.d/ | grep swaylock

# Test password authentication
sudo -k && sudo echo "Authentication test"
```

#### Config Not Loading
```bash
# Check config file path
ls -la ~/.config/swaylock/config

# Test with explicit config
swaylock-effects -C ~/.config/swaylock/config

# Verify config syntax
swaylock-effects --help
```

### Debug Commands
```bash
# Run with debug output
swaylock-effects --debug

# Check running processes
pgrep -fl swaylock

# View system logs
journalctl --user | grep swaylock
```

## Advanced Features

### Custom Scripts
Create wrapper scripts for different lock modes:
```bash
#!/bin/bash
# ~/.local/bin/lock-work
swaylock-effects \
    --color=2c3e50 \
    --effect-blur=5x3 \
    --text-color=ecf0f1 \
    --clock \
    --datestr="%A, %B %e" \
    --timestr="%H:%M"
```

### Theme Switching
```bash
#!/bin/bash
# Theme based on time of day
hour=$(date +%H)

if [ $hour -ge 6 ] && [ $hour -lt 18 ]; then
    # Day theme
    swaylock-effects -C ~/.config/swaylock/day-theme.conf
else
    # Night theme  
    swaylock-effects -C ~/.config/swaylock/night-theme.conf
fi
```

### Integration with Wallpaper
```bash
#!/bin/bash
# Use current wallpaper as lock screen background
current_wallpaper=$(variety --current)
swaylock-effects \
    --image="$current_wallpaper" \
    --effect-blur=3x2 \
    --scaling=fill
```

## Dependencies
- `swaylock-effects` - Enhanced swaylock with effects
- `pam` - Authentication system
- `wayland` - Display protocol
- Font: `JetBrainsMono Nerd Font Mono`
- `swayidle` - For automatic locking (optional)

## Related Tools
- **swayidle**: Automatic screen locking and power management
- **wlopm**: Manual display power management
- **hyprctl**: Hyprland control for DPMS
- **variety**: Wallpaper management integration

## File Locations
- **Config**: `~/.config/swaylock/config`
- **Themes**: `~/.config/swaylock/themes/` (custom)
- **Images**: `~/.config/swaylock/backgrounds/` (custom)
- **Scripts**: `~/.local/bin/lock-*` (custom wrappers)