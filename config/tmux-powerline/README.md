# 🔋 Tmux Powerline Configuration - User Guide

> **A comprehensive guide to your customized tmux-powerline status line setup**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [🎨 Visual Overview](#-visual-overview)
- [📊 Status Line Segments](#-status-line-segments)
- [🎯 Configuration Details](#-configuration-details)
- [🔧 Customization](#-customization)
- [🎨 Theme System](#-theme-system)
- [💡 Pro Tips](#-pro-tips)

---

## 🔧 Quick Start

### Prerequisites
- **Tmux**: Must be installed and configured
- **Patched Font**: Nerd Font or Powerline-compatible font required
- **Base16 Colors**: Theme inherits from your base16 color scheme

### Installation
Tmux-powerline is installed as a tmux plugin via TPM:
```bash
# Already configured in your tmux.conf
set -g @plugin 'erikw/tmux-powerline'
```

### Configuration Files
| File | Purpose |
|------|---------|
| `config.sh` | Main configuration and segment settings |
| `themes/theme.sh` | Visual theme and color definitions |

---

## 🎨 Visual Overview

### 📱 Two-Line Status Layout

Your tmux-powerline uses a **two-line status configuration**:

```
┌─────────────────────────────────────────────────────────────────┐
│  1:main    2:editor    3:server    4:logs                      │  ← Window List (Top)
├─────────────────────────────────────────────────────────────────┤
│ main:1.0  hostname  192.168.1.100  203.0.113.5  ~/project  │ 85%  2:30 PM  14:30 UTC  Dec-10-2024 │  ← Status Info (Bottom)
└─────────────────────────────────────────────────────────────────┘
```

### 🎨 Visual Elements
- **Top Line**: Window list with current directory navigation
- **Bottom Line**: System information and status segments
- **Powerline Separators**: Smooth transitions between segments
- **Color Inheritance**: Uses your base16 color scheme

---

## 📊 Status Line Segments

### 🔍 Left Status Segments
| Segment | Display | Description |
|---------|---------|-------------|
| **Session Info** | `main:1.0` | Current session:window.pane |
| **Hostname** | `hostname` | Current machine name (short format) |
| **LAN IP** | `📍 192.168.1.100` | Local network IP address |
| **WAN IP** | `🌐 203.0.113.5` | Public IP address |
| **Current Directory** | `~/project` | Working directory (max 40 chars) |

### 🔍 Right Status Segments
| Segment | Display | Description |
|---------|---------|-------------|
| **Battery** | `🔋 85%` | Battery percentage (laptops) |
| **Local Time** | `⏰ 2:30 PM` | Current time in America/La_Paz |
| **UTC Time** | `🌍 14:30 UTC` | UTC time for coordination |
| **Date** | `📅 Dec-10-2024` | Current date |

---

## 🎯 Configuration Details

### ⚙️ General Settings
| Setting | Value | Description |
|---------|-------|-------------|
| **Debug Mode** | `false` | Disabled for performance |
| **Patched Font** | `true` | Uses Nerd Font symbols |
| **Theme** | `theme` | Custom theme in themes/ directory |
| **Update Interval** | `1` second | Fast refresh rate |

### 📏 Layout Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| **Status Visibility** | `2` | Two-line status |
| **Window Status Line** | `0` | Windows on top line |
| **Justification** | `left` | Left-aligned window list |
| **Left Length** | `100` | Maximum left segment length |
| **Right Length** | `0` | No right length limit |

### 🎨 Color Scheme
- **Base Colors**: Inherits from terminal's base16 palette
- **Active Window**: Reverse video (background/foreground swapped)
- **Inactive Windows**: Default terminal colors
- **Segments**: Custom colors per segment for readability

---

## 🔧 Customization

### 🎨 Segment Colors
Each segment has customizable foreground and background colors:

```bash
# Format: "segment_name foreground_color background_color"
"tmux_session_info 148 234"  # Yellow on dark gray
"hostname           33  0"   # Blue on black
"lan_ip             208 0"   # Orange on black
"battery            226 234" # Bright yellow on dark gray
```

### 🔧 Segment Configuration

#### 🔋 Battery Segment
```bash
# Display type: percentage, cute, or hearts
export TMUX_POWERLINE_SEG_BATTERY_TYPE="percentage"
```

#### 📅 Date Segment
```bash
# Custom date format with icon
export TMUX_POWERLINE_SEG_DATE_FORMAT="󰨳 %b-%d-%Y"
```

#### 🏠 Hostname Segment
```bash
# Short format (just hostname, not FQDN)
export TMUX_POWERLINE_SEG_HOSTNAME_FORMAT="short"
```

#### 🌐 IP Address Segments
```bash
# Custom icons for IP addresses
export TMUX_POWERLINE_SEG_LAN_IP_SYMBOL=" "   # Local IP icon
export TMUX_POWERLINE_SEG_WAN_IP_SYMBOL=" "   # Public IP icon
```

#### 📁 Directory Segment
```bash
# Maximum path length before truncation
export TMUX_POWERLINE_SEG_PWD_MAX_LEN="40"
```

#### ⏰ Time Segments
```bash
# Local time format (12-hour with AM/PM)
export TMUX_POWERLINE_SEG_TIME_FORMAT="%I:%M %p"
export TMUX_POWERLINE_SEG_TIME_TZ="America/La_Paz"

# UTC time format
export TMUX_POWERLINE_SEG_UTC_TIME_FORMAT="%H:%M %Z"
```

#### 📊 Session Info
```bash
# Session format: Session:Window.Pane
export TMUX_POWERLINE_SEG_TMUX_SESSION_INFO_FORMAT="#S:#I.#P"
```

---

## 🎨 Theme System

### 🎨 Powerline Separators
The theme uses different separators based on font support:

#### With Patched Font (Nerd Font)
```bash
TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=" "   # Solid arrow
TMUX_POWERLINE_SEPARATOR_LEFT_THIN=" "   # Thin arrow
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=" "  # Solid arrow
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=" "  # Thin arrow
```

#### Without Patched Font (Fallback)
```bash
TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"   # Unicode arrow
TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"   # Unicode thin arrow
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"  # Unicode arrow
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"  # Unicode thin arrow
```

### 🎨 Window Status Styling

#### Active Window
- **Color**: Inverted (background becomes foreground)
- **Format**: `  1:main  ` (padded with spaces)
- **Style**: Bold/reverse video

#### Inactive Windows
- **Color**: Default terminal colors
- **Format**: `  2:editor  ` (padded with spaces)
- **Style**: Normal

---

## 💡 Pro Tips

### 🚀 Performance Optimization

#### Update Intervals
```bash
# Fast updates for development
export TMUX_POWERLINE_STATUS_INTERVAL="1"

# Slower updates for battery saving
export TMUX_POWERLINE_STATUS_INTERVAL="5"
```

#### Selective Segments
Remove unused segments to improve performance:
```bash
# Edit config.sh to remove segments you don't need
TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
  "tmux_session_info 148 234"
  "hostname           33  0"
  # Remove IP segments if not needed
  # "lan_ip             208 0"
  # "wan_ip             84  0"
  "pwd                99  255"
)
```

### 🎨 Visual Customization

#### Custom Icons
Add your own icons to segments:
```bash
# Custom icons for different segments
export TMUX_POWERLINE_SEG_DATE_FORMAT="📅 %b-%d-%Y"
export TMUX_POWERLINE_SEG_LAN_IP_SYMBOL="🏠 "
export TMUX_POWERLINE_SEG_WAN_IP_SYMBOL="🌍 "
```

#### Color Scheme Integration
Your powerline inherits colors from your base16 scheme:
```bash
# Terminal colors are used automatically
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR='terminal'
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR='terminal'
```

### 🔧 Advanced Configuration

#### Adding Custom Segments
1. **Create segment file**: `~/.config/tmux-powerline/segments/my_segment.sh`
2. **Add to config**: Include in `TMUX_POWERLINE_LEFT_STATUS_SEGMENTS`
3. **Set colors**: Define foreground/background colors

#### Debugging Issues
```bash
# Enable debug mode
export TMUX_POWERLINE_DEBUG_MODE_ENABLED="true"

# Check logs
tail -f ~/.tmux-powerline.log
```

### 🎯 Workflow Integration

#### Development Workflow
The status line provides key information for development:
- **Session Info**: Track which project you're working on
- **Directory**: See current working directory
- **Time Zones**: Coordinate with team across time zones
- **Network**: Monitor connectivity

#### System Monitoring
- **Battery**: Track laptop power during long sessions
- **Hostname**: Identify which machine you're on
- **IPs**: Network troubleshooting information

---

## 🔍 Troubleshooting

### Common Issues

#### Separators Not Showing
**Problem**: Arrows appear as question marks or boxes
**Solution**: Install a Nerd Font:
```bash
# Install via Homebrew
brew install font-jetbrains-mono-nerd-font

# Set in your terminal
font_family JetBrainsMono Nerd Font Mono
```

#### Slow Performance
**Problem**: Status line updates slowly
**Solution**: Reduce update frequency:
```bash
# In config.sh
export TMUX_POWERLINE_STATUS_INTERVAL="3"
```

#### Missing Segments
**Problem**: Some segments don't appear
**Solution**: Check segment dependencies:
```bash
# Battery segment needs battery command
which battery

# IP segments need network connectivity
ping -c 1 google.com
```

#### Colors Not Working
**Problem**: Wrong colors or no colors
**Solution**: Check terminal color support:
```bash
# Test 256 color support
echo $TERM
# Should be screen-256color in tmux
```

---

## 📚 Reference

### 📁 File Structure
```
~/.config/tmux-powerline/
├── config.sh                 # Main configuration
├── themes/
│   ├── theme.sh              # Custom theme
│   └── theme.sh.default      # Default theme backup
└── segments/                 # Custom segments (optional)
```

### 🎨 Color Reference
Common color codes used in configuration:
- `0` - Black
- `33` - Blue
- `84` - Cyan
- `99` - Purple
- `148` - Yellow
- `208` - Orange
- `226` - Bright yellow
- `234` - Dark gray
- `240` - Medium gray
- `244` - Light gray
- `255` - White

### 🔧 Segment Format
```bash
# Format: "segment_name foreground_color background_color [separator]"
"segment_name 148 234 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}"
```

---

> **💡 Pro Tip**: Your tmux-powerline configuration is optimized for development workflow with dual time zones, network monitoring, and project tracking. The two-line layout maximizes information density while maintaining readability!

**Happy status-lining!** 🚀