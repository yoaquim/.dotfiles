# Variety Wallpaper Management

## Overview
[Variety](https://github.com/varietywalls/variety) is a wallpaper manager for Linux systems that provides automatic wallpaper downloading and rotation. This configuration replaces the archived Unsplash integration with modern alternatives and integrates seamlessly with Hyprland.

## Features
- **Automatic Rotation**: Changes wallpapers at configurable intervals
- **Smart Learning**: Learns from user preferences over time  
- **Multiple Sources**: Local folders, Wallhaven, Reddit, Bing
- **API Integration**: Command-line control for scripts and hotkeys
- **Organization Tools**: Favorites, trash, and categorization
- **Hyprland Integration**: Works with hyprpaper for Wayland

## Installation Setup

### Initial Setup
Run the setup script to create directories and initial wallpapers:
```bash
~/.config/variety/scripts/setup-wallpapers.sh
```

This creates:
- `~/Pictures/Wallpapers/` - Local wallpaper collection
- `~/Pictures/Favorites/` - Favorite wallpapers
- `~/.config/variety/Downloaded/` - Auto-downloaded wallpapers
- Default gradient and solid color wallpapers

## Wallpaper Sources

### Local Sources
- **Personal Collection**: `~/Pictures/Wallpapers/`
- **Favorites**: Automatically saved favorite wallpapers
- **Downloaded**: Wallpapers from online sources

### Online Sources (Modern Alternatives)
1. **Wallhaven.cc**: High-quality wallpapers with tagging
2. **Reddit**: 
   - `/r/wallpapers` - General wallpaper collection
   - `/r/EarthPorn` - Nature photography
3. **Bing**: Daily featured photos

### Deprecated Sources (Disabled)
- Unsplash (API archived)
- Flickr (less reliable)

## Controls and Shortcuts

### Via swhkd Integration
| Shortcut | Action |
|---|---|
| `Super + Alt + N` | Next wallpaper |
| `Super + Alt + P` | Previous wallpaper |
| `Super + Alt + F` | Favorite current wallpaper |
| `Super + Alt + T` | Trash current wallpaper |

### Command Line API
```bash
variety --next          # Next wallpaper
variety --previous      # Previous wallpaper  
variety --favorite      # Favorite current
variety --trash         # Trash current
variety --pause         # Pause auto-rotation
variety --resume        # Resume auto-rotation
variety --current       # Show current wallpaper path
variety --history       # Show recent wallpapers
variety --set /path/to/image  # Set specific wallpaper
```

## Configuration Settings

### Timing
- **Change Interval**: 30 minutes (1800 seconds)
- **Download Interval**: 1 hour (3600 seconds)
- **Safe Mode**: Disabled (changes even during fullscreen apps)

### Quality Preferences
- **Preferred Resolution**: 1920x1080
- **Minimum Size**: 500KB
- **Smart Learning**: Enabled (learns from favorites/trash)
- **Minimum Rating**: 4/5 for auto-selection

### Storage Management
- **Download Quota**: 1GB limit
- **History Length**: 50 previous wallpapers
- **Trash Enabled**: Move to trash instead of permanent delete

## Hyprland Integration

### Wallpaper Setting Command
Variety uses a custom command for Hyprland:
```bash
hyprctl hyprpaper wallpaper ",{}"
```

### Hyprpaper Configuration
- **Preload**: Default fallback wallpapers loaded into memory
- **IPC**: Enabled for dynamic wallpaper changes
- **Splash**: Disabled for faster startup

### Autostart Integration
Added to Hyprland config:
```bash
exec-once = variety
exec-once = hyprpaper
```

## Advanced Features

### Smart Operation
- Learns from user actions (favorites, trash, skip)
- Builds preference model over time
- Automatically filters similar-quality images
- Rating system for automatic curation

### Image Processing
- **Display Mode**: Zoom (maintains aspect ratio)
- **Size Filtering**: Minimum resolution and file size
- **Format Support**: JPG, PNG, WebP, and other common formats

### Organization Tools
- **Favorites**: Automatic copying to favorites folder
- **Copy To**: Organize wallpapers into categories
- **History**: Track recent wallpaper changes
- **Statistics**: Usage tracking and preferences

## Customization

### Adding Custom Sources
Edit `variety.conf` to add new sources:
```python
[{"url": "/path/to/folder", "name": "Custom Folder", "enabled": true, "type": "folder"}]
```

### Changing Intervals
Modify timing settings:
```python
change_interval = 3600    # 1 hour
download_interval = 7200  # 2 hours
```

### Custom Scripts
Place scripts in `~/.config/variety/scripts/` for custom actions:
```bash
# Custom wallpaper filter
~/scripts/process-wallpaper.sh "$VARIETY_WALLPAPER_PATH"
```

## Integration with Other Tools

### Waybar Integration
Shows current wallpaper info in status bar (optional module)

### Rofi Integration  
Create wallpaper selection menu:
```bash
ls ~/Pictures/Wallpapers/ | rofi -dmenu -p "Select Wallpaper" | xargs variety --set
```

### Notifications
Desktop notifications for wallpaper changes (if desired)

## Troubleshooting

### Common Issues
1. **Wallpapers not changing**: Check if variety daemon is running
2. **Hyprland integration fails**: Verify hyprpaper is installed and running
3. **Downloads not working**: Check internet connection and source URLs
4. **Permission errors**: Ensure directories are writable

### Debug Commands
```bash
# Check variety status
ps aux | grep variety

# View logs  
variety --debug

# Reset configuration
rm ~/.config/variety/variety.db

# Manual wallpaper test
variety --set ~/Pictures/Wallpapers/default.jpg
```

### Performance
- Uses minimal resources when idle
- Downloads happen in background
- Smart caching prevents re-downloading
- Configurable quota prevents excessive disk usage

## Dependencies
- `variety` - The wallpaper manager
- `hyprpaper` - Hyprland wallpaper utility
- `python3` - For variety operation
- `curl`/`wget` - For downloading wallpapers
- `imagemagick` - For image processing (optional)

## File Locations
- **Config**: `~/.config/variety/variety.conf`
- **Database**: `~/.config/variety/variety.db`
- **Scripts**: `~/.config/variety/scripts/`
- **Cache**: `~/.cache/variety/`
- **Wallpapers**: `~/Pictures/Wallpapers/`