# 🐱 Kitty Terminal Configuration - User Guide

> **A comprehensive guide to your customized Kitty terminal emulator setup**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [🎨 Visual Configuration](#-visual-configuration)
- [⌨️ Keyboard Shortcuts](#️-keyboard-shortcuts)
- [🖱️ Mouse & Selection](#️-mouse--selection)
- [🪟 Window Management](#-window-management)
- [📑 Tab Management](#-tab-management)
- [⚡ Performance Settings](#-performance-settings)
- [🔧 Advanced Features](#-advanced-features)
- [💡 Pro Tips](#-pro-tips)

---

## 🔧 Quick Start

### Installation & Setup

1. **Install Kitty**:
   ```bash
   # macOS
   brew install kitty
   
   # Linux
   curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
   ```

2. **Link Configuration**:
   ```bash
   ln -sf ~/.dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
   ```

3. **Launch Kitty**:
   ```bash
   kitty
   ```

4. **Reload Configuration**:
   - `Ctrl+Shift+F5` - Reload config
   - Or restart Kitty

---

## 🎨 Visual Configuration

### 🔤 Font Settings
| Setting | Value | Description |
|---------|-------|-------------|
| **Font Family** | `CaskaydiaCove Nerd Font Mono` | Main font with programming ligatures |
| **Font Size** | `13` | Comfortable reading size |
| **Bold Font** | `auto` | Automatic bold variant |
| **Italic Font** | `auto` | Automatic italic variant |
| **Line Height** | `0` (default) | No adjustment to line spacing |
| **Column Width** | `0` (default) | No adjustment to character width |

### 🖼️ Window Appearance
| Setting | Value | Description |
|---------|-------|-------------|
| **Window Padding** | `10` pixels | Comfortable padding around content |
| **Window Decorations** | `no` (hidden) | Clean, minimal appearance |
| **Remember Window Size** | `yes` | Restore window size on restart |
| **Audio Bell** | `yes` | Enabled for notifications |

### 📜 Scrollback Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| **Scrollback Lines** | `50,000` | Large history buffer |
| **Scrollback Pager** | `less` | Use less for viewing history |
| **Wheel Scroll Multiplier** | `5.0` | Faster scrolling |

---

## ⌨️ Keyboard Shortcuts

### 🔧 Built-in Kitty Shortcuts

#### Window Management
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+Enter` | New window |
| `Ctrl+Shift+W` | Close window |
| `Ctrl+Shift+]` | Next window |
| `Ctrl+Shift+[` | Previous window |
| `Ctrl+Shift+F` | Move window forward |
| `Ctrl+Shift+B` | Move window backward |
| `Ctrl+Shift+R` | Resize window |

#### Tab Management
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+Q` | Close tab |
| `Ctrl+Shift+Right` | Next tab |
| `Ctrl+Shift+Left` | Previous tab |
| `Ctrl+Shift+Alt+T` | Set tab title |
| `Ctrl+Shift+L` | Next layout |

#### Text & Selection
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+C` | Copy to clipboard |
| `Ctrl+Shift+V` | Paste from clipboard |
| `Ctrl+Shift+S` | Paste from selection |
| `Ctrl+Shift+Up` | Scroll line up |
| `Ctrl+Shift+Down` | Scroll line down |
| `Ctrl+Shift+Page Up` | Scroll page up |
| `Ctrl+Shift+Page Down` | Scroll page down |
| `Ctrl+Shift+Home` | Scroll to top |
| `Ctrl+Shift+End` | Scroll to bottom |

#### Configuration & Debug
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+F5` | Reload configuration |
| `Ctrl+Shift+F6` | Debug configuration |
| `Ctrl+Shift+Delete` | Clear terminal |
| `Ctrl+Shift+F11` | Toggle fullscreen |
| `Ctrl+Shift+F10` | Toggle maximized |

---

## 🖱️ Mouse & Selection

### 🖱️ Mouse Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| **Mouse Hide Wait** | `3.0` seconds | Auto-hide mouse cursor |
| **URL Color** | `cyan` | Highlight URLs in cyan |
| **Copy on Select** | `yes` | Auto-copy selected text |
| **Open URL With** | `default` | Use system default browser |

### 🖱️ Mouse Actions
| Action | Behavior |
|--------|----------|
| **Single Click** | Place cursor |
| **Double Click** | Select word |
| **Triple Click** | Select line |
| **Click + Drag** | Select text |
| **Ctrl + Click** | Open URL |
| **Shift + Click** | Extend selection |
| **Middle Click** | Paste selection |
| **Scroll Wheel** | Scroll content |

---

## 🪟 Window Management

### 🖼️ Window Features
- **Padding**: 10px on all sides for comfortable viewing
- **Decorations**: Hidden for clean appearance
- **Size Memory**: Window size restored on restart
- **Bell**: Audio notifications enabled

### 🪟 Window Layouts
Kitty supports multiple window layouts:
- **Tall**: One large window, others stacked
- **Fat**: One large window, others side by side
- **Grid**: Windows arranged in a grid
- **Horizontal**: Windows arranged horizontally
- **Vertical**: Windows arranged vertically

### 🎯 Window Navigation
Use `Ctrl+Shift+[` and `Ctrl+Shift+]` to navigate between windows, or click on the desired window.

---

## 📑 Tab Management

### 🎨 Tab Appearance
| Setting | Value | Description |
|---------|-------|-------------|
| **Tab Bar Edge** | `top` | Tabs at top of window |
| **Tab Bar Style** | `powerline` | Angled powerline style |
| **Active Tab Font** | `bold` | Bold font for active tab |
| **Inactive Tab Font** | `normal` | Normal font for inactive tabs |

### 📑 Tab Workflow
1. **Create New Tab**: `Ctrl+Shift+T`
2. **Switch Tabs**: `Ctrl+Shift+Left/Right`
3. **Name Tab**: `Ctrl+Shift+Alt+T`
4. **Close Tab**: `Ctrl+Shift+Q`

### 🎯 Tab Organization
- **Name your tabs** for better organization
- **Use multiple tabs** for different projects
- **Powerline style** provides visual separation

---

## ⚡ Performance Settings

### 🚀 Optimization Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| **Input Delay** | `1` ms | Minimal input latency |
| **Repaint Delay** | `10` ms | Fast screen updates |
| **Sync to Monitor** | `yes` | Smooth scrolling |

### 🎯 Performance Benefits
- **Low Latency**: Responsive typing and commands
- **Smooth Scrolling**: Fluid text movement
- **Monitor Sync**: Eliminates screen tearing
- **Efficient Rendering**: Fast text display

---

## 🔧 Advanced Features

### 🔗 URL Handling
- **Automatic Detection**: URLs automatically highlighted
- **Click to Open**: Ctrl+Click to open URLs
- **Color Coding**: URLs shown in cyan
- **Default Browser**: Opens with system default

### 📋 Clipboard Integration
- **Copy on Select**: Text automatically copied when selected
- **Multiple Clipboards**: System clipboard and selection buffer
- **Cross-Platform**: Works on macOS, Linux, and Windows

### 🔄 Configuration Reloading
- **Hot Reload**: Changes applied without restart
- **Debug Mode**: `Ctrl+Shift+F6` for configuration debugging
- **Validation**: Automatic syntax checking

---

## 💡 Pro Tips

### 🎯 Productivity Shortcuts

#### Quick Configuration Editing
```bash
# Edit kitty config
vk                          # Opens kitty.conf in nvim

# Test configuration
kitty --debug-config        # Debug configuration issues
```

#### Multiple Sessions
```bash
# Start new kitty session
kitty --session session.conf

# Start with specific directory
kitty --directory ~/Projects
```

#### Remote Sessions
```bash
# SSH with kitty terminfo
kitty +kitten ssh myserver

# Copy file to remote
kitty +kitten transfer file.txt myserver:~/
```

### 🔧 Customization Tips

#### Font Optimization
- **Nerd Font**: Includes programming symbols and icons
- **Ligatures**: Automatic for programming fonts
- **Size**: Adjust based on monitor resolution
- **Anti-aliasing**: Automatic for crisp text

#### Window Management
- **Layouts**: Experiment with different layouts
- **Splits**: Use multiple windows for complex workflows
- **Tabs**: Organize by project or task

#### Performance Tuning
- **GPU Acceleration**: Enabled by default
- **Memory Usage**: Large scrollback for development
- **Sync**: Monitor sync prevents tearing

### 🎨 Visual Customization

#### Color Themes
Kitty supports external color schemes:
```bash
# Download themes
git clone https://github.com/dexpota/kitty-themes.git ~/.config/kitty/themes

# Apply theme
ln -sf ~/.config/kitty/themes/Dracula.conf ~/.config/kitty/theme.conf
echo "include theme.conf" >> ~/.config/kitty/kitty.conf
```

#### Window Styling
```bash
# Transparency (add to kitty.conf)
background_opacity 0.9

# Blur (macOS only)
background_blur 20
```

### 🔄 Integration with Other Tools

#### Tmux Integration
```bash
# Better tmux integration
export TERM=xterm-kitty
```

#### Shell Integration
```bash
# Add to ~/.bashrc or ~/.zshrc
if [ "$TERM" = "xterm-kitty" ]; then
    alias ssh="kitty +kitten ssh"
fi
```

#### Development Workflow
1. **Multiple Tabs**: One per project
2. **Window Splits**: Editor + terminal
3. **Remote Sessions**: SSH with kitty features
4. **File Transfer**: Built-in file transfer

---

## 🔍 Troubleshooting

### Common Issues

#### Font Not Found
```bash
# List available fonts
kitty +list-fonts

# Install JetBrains Mono
brew install font-jetbrains-mono-nerd-font
```

#### Performance Issues
```bash
# Check GPU acceleration
kitty --debug-gl

# Reduce scrollback if needed
scrollback_lines 5000
```

#### SSH Issues
```bash
# Use kitty's SSH kitten
kitty +kitten ssh user@host

# Or set TERM manually
export TERM=xterm-256color
```

---

> **💡 Pro Tip**: Use `Ctrl+Shift+F5` to reload configuration after making changes, and `Ctrl+Shift+F6` to debug any configuration issues!

**Happy terminal-ing!** 🚀