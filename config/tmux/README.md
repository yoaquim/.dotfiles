# 🖥️ Tmux Configuration - User Guide

> **A comprehensive guide to your customized tmux terminal multiplexer setup with powerful plugins**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [⌨️ Key Bindings](#️-key-bindings)
- [🪟 Window Management](#-window-management)
- [📱 Pane Management](#-pane-management)
- [🔌 Plugins](#-plugins)
- [🎨 Customization](#-customization)
- [🔄 Session Management](#-session-management)
- [💡 Pro Tips](#-pro-tips)

---

## 🔧 Quick Start

### Installation & Setup

1. **Install Tmux**:
   ```bash
   # macOS
   brew install tmux
   
   # Linux
   sudo apt install tmux  # Ubuntu/Debian
   sudo yum install tmux  # CentOS/RHEL
   ```

2. **Link Configuration**:
   ```bash
   ln -sf ~/.dotfiles/config/tmux/tmux.conf ~/.config/tmux/tmux.conf
   ```

3. **Install Plugin Manager**:
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
   ```

4. **Start Tmux & Install Plugins**:
   ```bash
   tmux
   # Inside tmux, press: ` + I (capital i) to install plugins
   ```

### 🎯 Custom Prefix Key
**Important**: This configuration uses **backtick (`)** as the prefix key instead of the default `Ctrl+b`.

| Action | Shortcut |
|--------|----------|
| **Send Prefix** | `` ` `` |
| **Send Literal Backtick** | `` ` ` `` |

---

## ⌨️ Key Bindings

### 🪟 Window Navigation
| Shortcut | Action |
|----------|--------|
| `` ` , `` | Previous window |
| `` ` . `` | Next window |
| `` ` H `` | Previous window (alternative) |
| `` ` L `` | Next window (alternative) |
| `` ` u `` | Previous window (alternative) |
| `` ` i `` | Next window (alternative) |

### 📱 Pane Navigation
| Shortcut | Action |
|----------|--------|
| `` ` h `` | Select left pane |
| `` ` j `` | Select pane below |
| `` ` k `` | Select pane above |
| `` ` l `` | Select right pane |

### 🔀 Pane Splitting
| Shortcut | Action |
|----------|--------|
| `` ` \ `` | Split pane horizontally (left/right) |
| `` ` - `` | Split pane vertically (top/bottom) |

### 📏 Pane Resizing
| Shortcut | Action |
|----------|--------|
| `` ` Left `` | Resize pane left by 5 |
| `` ` Right `` | Resize pane right by 5 |
| `` ` Up `` | Resize pane up by 5 |
| `` ` Down `` | Resize pane down by 5 |

### 🎨 Layout Management
| Shortcut | Action |
|----------|--------|
| `` ` v `` | Even horizontal layout |
| `` ` b `` | Even vertical layout |
| `` ` t `` | Tiled layout |
| `` ` o `` | Rotate panes |

### 🏷️ Naming & Management
| Shortcut | Action |
|----------|--------|
| `` ` n `` | Rename current window |
| `` ` N `` | Rename current session |
| `` ` m `` | Move window to index |
| `` ` x `` | Kill current pane |
| `` ` X `` | Kill current window |

### 🔄 System Commands
| Shortcut | Action |
|----------|--------|
| `` ` Space `` | Command prompt |
| `` ` r `` | Reload tmux configuration |

---

## 🪟 Window Management

### 🎯 Window Features
- **Base Index**: Windows start at 1 (not 0)
- **Automatic Rename**: Windows auto-rename based on running command
- **Set Titles**: Window titles shown in terminal title bar
- **Aggressive Resize**: Efficient window resizing

### 🔄 Window Workflow
1. **Create Window**: `Ctrl+c` (default tmux binding)
2. **Navigate**: `` ` , `` and `` ` . `` for previous/next
3. **Rename**: `` ` n `` to give meaningful names
4. **Move**: `` ` m `` to reorganize window order
5. **Close**: `` ` X `` to kill window

### 🎨 Window Layouts
Switch between predefined layouts:
- **Even Horizontal** (`` ` v ``): Panes side by side
- **Even Vertical** (`` ` b ``): Panes stacked vertically
- **Tiled** (`` ` t ``): Grid layout for multiple panes

---

## 📱 Pane Management

### 🔀 Pane Creation
| Action | Command |
|--------|---------|
| **Horizontal Split** | `` ` \ `` |
| **Vertical Split** | `` ` - `` |

### 🧭 Pane Navigation
- **Vim-style**: `h`, `j`, `k`, `l` for left, down, up, right
- **Intuitive**: Matches vim movement keys
- **Fast**: No Ctrl modifier needed after prefix

### 📏 Pane Resizing
- **Arrow Keys**: Use with prefix for precise control
- **Increment**: 5-cell adjustments for fine-tuning
- **Visual**: See changes immediately

### 🎯 Pane Features
- **Vi Mode**: Vi-style key bindings for copy mode
- **Mouse Support**: Click to select, drag to resize
- **History**: 50,000 lines of scrollback per pane

---

## 🔌 Plugins

### 📦 Installed Plugins

#### 1. **TPM (Tmux Plugin Manager)**
- **Purpose**: Plugin installation and management
- **Usage**: `` ` I `` (install), `` ` U `` (update), `` ` alt + u `` (uninstall)

#### 2. **Tmux Resurrect**
- **Purpose**: Save and restore tmux sessions
- **Usage**: 
  - `` ` Ctrl+s `` - Save session
  - `` ` Ctrl+r `` - Restore session
- **Features**: Preserves panes, windows, and working directories

#### 3. **Tmux Continuum**
- **Purpose**: Automatic session saving and restoration
- **Configuration**: `@continuum-restore 'on'`
- **Features**: Auto-saves every 15 minutes, restores on tmux start

#### 4. **Tmux Yank**
- **Purpose**: Enhanced clipboard integration
- **Usage**:
  - `y` - Copy selection to system clipboard
  - `Y` - Copy current line to system clipboard
  - `Enter` - Copy and exit copy mode

#### 5. **Tmux Powerline**
- **Purpose**: Enhanced status line with themes
- **Features**: Shows system info, git status, and more
- **Configuration**: Uses custom theme from `~/.dotfiles/config/tmux-powerline/`

#### 6. **Tmux Mighty Scroll**
- **Purpose**: Improved scrolling performance
- **Features**: Faster scrolling, better mouse wheel support

#### 7. **Tmux Better Mouse Mode**
- **Purpose**: Enhanced mouse support
- **Features**: Better mouse wheel scrolling, improved selection

#### 8. **Tmux Fingers**
- **Purpose**: Quick text selection and copying
- **Usage**: `` ` F `` to activate, then use highlighted letters
- **Features**: Automatically highlights URLs, paths, and text

---

## 🎨 Customization

### 🎨 Visual Settings
| Setting | Value | Description |
|---------|-------|-------------|
| **Visual Activity** | `off` | No activity indicators |
| **Visual Bell** | `off` | No visual bell |
| **Bell Action** | `none` | No bell actions |
| **Monitor Activity** | `off` | No activity monitoring |

### 🖱️ Mouse Configuration
- **Mouse Support**: Enabled for clicking, dragging, and scrolling
- **Focus Events**: Enabled for better terminal integration
- **Xterm Keys**: Enabled for better key support

### 🎯 Behavior Settings
| Setting | Value | Description |
|---------|-------|-------------|
| **History Limit** | `50,000` | Large scrollback buffer |
| **Display Time** | `4,000ms` | Message display duration |
| **Status Interval** | `5s` | Status line update frequency |
| **Default Terminal** | `screen-256color` | Full color support |

---

## 🔄 Session Management

### 📁 Basic Session Commands
```bash
# Start new session
tmux new-session -s mysession

# List sessions
tmux list-sessions

# Attach to session
tmux attach-session -t mysession

# Kill session
tmux kill-session -t mysession
```

### 🔄 Session Persistence
With **tmux-resurrect** and **tmux-continuum**:
- **Auto-save**: Sessions saved every 15 minutes
- **Auto-restore**: Sessions restored on tmux start
- **Manual control**: `` ` Ctrl+s `` to save, `` ` Ctrl+r `` to restore

### 🎯 Session Workflow
1. **Create**: `tmux new-session -s project`
2. **Setup**: Create windows and panes for your workflow
3. **Work**: Use tmux normally
4. **Detach**: `Ctrl+d` or `` ` d `` to detach
5. **Reattach**: `tmux attach -t project`

---

## 💡 Pro Tips

### 🚀 Productivity Workflows

#### Development Setup
```bash
# Create development session
tmux new-session -s dev -d
tmux send-keys -t dev 'cd ~/Projects/myproject' Enter
tmux split-window -t dev -v
tmux send-keys -t dev 'nvim' Enter
tmux split-window -t dev -h
tmux send-keys -t dev 'npm run dev' Enter
tmux attach -t dev
```

#### Quick Window Navigation
```bash
# Use aliases for faster access
alias tm='tmux'
alias tma='tmux attach -t'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'
```

### 🎯 Plugin Usage Tips

#### Tmux Fingers Workflow
1. Press `` ` F `` to activate fingers mode
2. Look for highlighted letters over URLs, paths, files
3. Press the highlighted letter to copy that item
4. Paste with `` ` ] `` or system paste

#### Resurrect Best Practices
- **Save often**: `` ` Ctrl+s `` before risky operations
- **Restore specific**: Can restore individual sessions
- **Customize**: Edit `~/.tmux/resurrect/` files if needed

### 🔧 Configuration Management

#### Reload Configuration
```bash
# Method 1: Using keybinding
` r

# Method 2: From command line
tmux source-file ~/.config/tmux/tmux.conf
```

#### Edit Configuration
```bash
# Edit tmux config (using bash alias)
vt

# Test configuration
tmux source-file ~/.config/tmux/tmux.conf
```

### 🎨 Advanced Customization

#### Custom Key Bindings
Add to `tmux.conf`:
```bash
# Custom binding example
bind-key C-a send-prefix    # Alternative prefix
bind-key | split-window -h  # Alternative split
```

#### Status Line Customization
```bash
# Custom status line
set -g status-right '#H #(uptime | cut -d "," -f 3-)'
```

### 🔍 Debugging

#### Check Plugin Status
```bash
# Inside tmux
` I    # Install plugins
` U    # Update plugins
` alt + u    # Uninstall plugins
```

#### Troubleshooting
```bash
# Check tmux info
tmux info

# Verify configuration
tmux source-file ~/.config/tmux/tmux.conf
```

---

## 🔍 Common Issues & Solutions

### Plugin Installation Issues
```bash
# Ensure tpm is installed
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install plugins
tmux
` I
```

### Mouse Not Working
```bash
# Ensure mouse is enabled in config
set-option -g mouse on
```

### Colors Not Working
```bash
# Check terminal support
echo $TERM
# Should be screen-256color inside tmux
```

---

> **💡 Pro Tip**: Use `` ` r `` to reload configuration after making changes, and remember that your prefix key is backtick (`) not Ctrl+b!

**Happy tmux-ing!** 🚀