# Hyprpaper Configuration

## Overview
[Hyprpaper](https://github.com/hyprwm/hyprpaper) is a blazing fast wallpaper utility for Hyprland with IPC controls. It's designed specifically for the Hyprland ecosystem and provides efficient wallpaper management with dynamic switching capabilities.

## Features
- **Fast Performance**: Optimized for speed and minimal resource usage
- **IPC Control**: Dynamic wallpaper changes via hyprctl commands
- **Multi-Monitor Support**: Independent wallpapers for each monitor
- **Memory Preloading**: Preloads wallpapers for instant switching
- **Wayland Native**: Built specifically for Wayland compositors

## Configuration

### Basic Setup
The configuration file is located at `~/.config/hypr/hyprpaper.conf` and contains:

```conf
# Preload wallpapers into memory
preload = ~/Pictures/Wallpapers/default.jpg
preload = ~/Pictures/Wallpapers/fallback.png

# Set wallpaper for all monitors
wallpaper = ,~/Pictures/Wallpapers/default.jpg

# Enable IPC for dynamic changes
ipc = on

# Disable splash for faster startup
splash = false
```

### Preloading Wallpapers
Preloading puts wallpapers into memory for instant switching:
```conf
preload = /path/to/wallpaper1.jpg
preload = /path/to/wallpaper2.png
preload = /path/to/wallpaper3.webp
```

### Setting Wallpapers
Apply preloaded wallpapers to monitors:
```conf
# All monitors
wallpaper = ,/path/to/wallpaper.jpg

# Specific monitor
wallpaper = DP-1,/path/to/wallpaper.jpg
wallpaper = HDMI-1,/path/to/different-wallpaper.png
```

## Dynamic Control

### Via hyprctl Commands
Change wallpapers dynamically using hyprctl:
```bash
# Change wallpaper on all monitors
hyprctl hyprpaper wallpaper ",/path/to/new-wallpaper.jpg"

# Change wallpaper on specific monitor
hyprctl hyprpaper wallpaper "DP-1,/path/to/wallpaper.jpg"

# Preload new wallpaper
hyprctl hyprpaper preload /path/to/wallpaper.jpg

# Unload wallpaper from memory
hyprctl hyrrpaper unload /path/to/wallpaper.jpg

# List loaded wallpapers
hyprctl hyprpaper listloaded

# List active wallpapers
hyprctl hyprpaper listactive
```

### Integration with Scripts
Create scripts for wallpaper management:
```bash
#!/bin/bash
# Random wallpaper script
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n1)
hyprctl hyrrpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"
```

## Multi-Monitor Configuration

### Per-Monitor Wallpapers
Set different wallpapers for each monitor:
```conf
# Monitor configuration
preload = ~/Pictures/Wallpapers/monitor1.jpg
preload = ~/Pictures/Wallpapers/monitor2.jpg
preload = ~/Pictures/Wallpapers/monitor3.jpg

# Apply to specific monitors
wallpaper = DP-1,~/Pictures/Wallpapers/monitor1.jpg
wallpaper = DP-2,~/Pictures/Wallpapers/monitor2.jpg
wallpaper = HDMI-1,~/Pictures/Wallpapers/monitor3.jpg
```

### Finding Monitor Names
Discover available monitors:
```bash
# List monitors in Hyprland
hyprctl monitors

# Using xrandr (if available)
xrandr --listmonitors
```

## Integration with Variety

### Automatic Wallpaper Changes
Variety integrates with hyprpaper using the custom command:
```python
# In variety.conf
set_wallpaper_script = hyprctl hyprpaper wallpaper ",{}"
```

### Workflow
1. **Variety** selects/downloads wallpapers
2. **Variety** calls hyprctl command
3. **Hyprpaper** receives IPC command
4. **Hyprpaper** switches wallpaper instantly

## Autostart Configuration

### Via Hyprland Config
Add to `~/.config/hypr/hyprland.conf`:
```conf
exec-once = hyprpaper
```

### Via Systemd (Optional)
Create user service for automatic startup:
```ini
# ~/.config/systemd/user/hyprpaper.service
[Unit]
Description=Hyprpaper wallpaper daemon
PartOf=hyprland.service

[Service]
ExecStart=/usr/bin/hyprpaper
Restart=always
RestartSec=1

[Install]
WantedBy=hyprland.service
```

## Performance Optimization

### Memory Management
- **Preload wisely**: Only preload frequently used wallpapers
- **Unload unused**: Remove wallpapers from memory when not needed
- **Monitor usage**: Check loaded wallpapers with `listloaded`

### File Formats
- **JPG**: Best for photographs, smaller file size
- **PNG**: Best for graphics with transparency
- **WebP**: Good compression with quality
- **Avoid**: Very large uncompressed formats

### Fast Switching
```bash
# Preload multiple wallpapers for instant switching
hyprctl hyprpaper preload ~/Pictures/Wallpapers/wallpaper1.jpg
hyprctl hyprpaper preload ~/Pictures/Wallpapers/wallpaper2.jpg
hyprctl hyprpaper preload ~/Pictures/Wallpapers/wallpaper3.jpg

# Switch instantly between preloaded wallpapers
hyprctl hyprpaper wallpaper ",~/Pictures/Wallpapers/wallpaper1.jpg"
hyprctl hyprpaper wallpaper ",~/Pictures/Wallpapers/wallpaper2.jpg"
```

## Troubleshooting

### Common Issues
1. **Wallpaper not changing**: Check if hyprpaper daemon is running
2. **File not found**: Verify wallpaper paths are absolute and exist
3. **Permission errors**: Ensure wallpaper files are readable
4. **IPC failures**: Confirm `ipc = on` in configuration

### Debug Commands
```bash
# Check if hyprpaper is running
pgrep hyprpaper

# View hyprpaper logs
journalctl --user -u hyprpaper.service

# Test manual wallpaper setting
hyprctl hyprpaper wallpaper ",/usr/share/pixmaps/arch-linux.png"

# Verify IPC connection
hyprctl hyprpaper listloaded
```

### Recovery Steps
```bash
# Kill and restart hyprpaper
pkill hyprpaper
hyprpaper &

# Reload Hyprland configuration
hyprctl reload

# Check configuration syntax
hyprpaper --config ~/.config/hypr/hyprpaper.conf --check
```

## Advanced Configuration

### Conditional Wallpapers
Use scripts for time-based or condition-based wallpaper changes:
```bash
#!/bin/bash
# Time-based wallpaper script
HOUR=$(date +%H)

if [ $HOUR -ge 6 ] && [ $HOUR -lt 18 ]; then
    # Daytime wallpaper
    WALLPAPER="$HOME/Pictures/Wallpapers/day.jpg"
else
    # Nighttime wallpaper  
    WALLPAPER="$HOME/Pictures/Wallpapers/night.jpg"
fi

hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"
```

### Monitor-Specific Scripts
Handle multi-monitor setups dynamically:
```bash
#!/bin/bash
# Set wallpapers based on monitor configuration
MONITORS=($(hyprctl monitors -j | jq -r '.[].name'))

for monitor in "${MONITORS[@]}"; do
    wallpaper="$HOME/Pictures/Wallpapers/${monitor}.jpg"
    if [ -f "$wallpaper" ]; then
        hyprctl hyprpaper preload "$wallpaper"
        hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
    fi
done
```

## Dependencies
- `hyprpaper` - The wallpaper daemon
- `hyprland` - The compositor (for IPC)
- `jq` - For JSON parsing in scripts (optional)
- Image files in supported formats (JPG, PNG, WebP)

## File Locations
- **Config**: `~/.config/hypr/hyprpaper.conf`
- **Wallpapers**: `~/Pictures/Wallpapers/` (recommended)
- **Cache**: `~/.cache/hyprpaper/` (if applicable)