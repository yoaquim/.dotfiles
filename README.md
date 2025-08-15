# 🏡 Dotfiles - Complete Development Environment Setup

> **A comprehensive, automated macOS development environment with modern tools and configurations**

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [⚡ What's Included](#-whats-included)
- [🔧 Installation](#-installation)
- [📁 Configuration Structure](#-configuration-structure)
- [🛠️ Tools & Applications](#️-tools--applications)
- [🎨 Customization](#-customization)
- [🔄 Management](#-management)
- [💡 Pro Tips](#-pro-tips)
- [🔍 Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Prerequisites

#### macOS
- **macOS** (any recent version)
- **Command Line Tools** for Xcode
- **Internet connection** for downloading tools

#### Linux (Fedora)
- **Fedora** (traditional) or **Fedora Atomic** (Silverblue/Kinoite/Sericea)
- **Internet connection** for downloading packages
- **sudo privileges** for system package installation
- **Flathub enabled** (for Atomic variants)

### Two-Step Installation

#### Step 1: Core Installation
```bash
# Clone and install core components (use bash explicitly for color support)
cd ~ && git clone https://github.com/yoaquim/.dotfiles.git && cd .dotfiles && bash ./install.sh
```

#### Step 2: Language Environments
```bash
# Setup Node.js and Python environments (use bash explicitly)
bash ./post-setup.sh
```

### Manual Installation

#### macOS
```bash
# 1. Clone the repository
cd ~/
git clone https://github.com/yoaquim/.dotfiles.git

# 2. Run core installation script (use bash explicitly for colors)
cd ~/.dotfiles
bash ./install.sh

# 3. Setup language environments (use bash explicitly)
bash ./post-setup.sh
```

#### Linux (Fedora Traditional)
```bash
# 1. Clone the repository
cd ~/
git clone https://github.com/yoaquim/.dotfiles.git

# 2. Run installation script (automatically detects Linux)
cd ~/.dotfiles
bash ./install.sh

# 3. Setup language environments and AstroNvim
bash ./post-setup.sh

# 4. Build swhkd hotkey daemon (manual build required)
sudo dnf install rust cargo make git polkit-devel scdoc
git clone https://github.com/waycrate/swhkd.git /tmp/swhkd
cd /tmp/swhkd && make build && sudo make install

# 5. Initialize wallpaper setup
~/.config/variety/scripts/setup-wallpapers.sh
```

#### Linux (Fedora Atomic/Silverblue)
```bash
# 1. Clone the repository
cd ~/
git clone https://github.com/yoaquim/.dotfiles.git

# 2. Run installation script (detects Atomic automatically)
cd ~/.dotfiles
bash ./install.sh

# 3. REBOOT REQUIRED after system package installation
sudo systemctl reboot

# 4. After reboot, complete setup
cd ~/.dotfiles
bash ./post-setup.sh

# 5. Build swhkd hotkey daemon (dependencies already installed)
git clone https://github.com/waycrate/swhkd.git /tmp/swhkd
cd /tmp/swhkd && make build && sudo make install

# 6. Initialize wallpaper setup
~/.config/variety/scripts/setup-wallpapers.sh
```

---

## ⚡ What's Included

### 🐚 **Shell Environment** (Cross-Platform)
- **Modern Bash** with vim-style editing
- **50+ custom aliases** for productivity (OS-aware clipboard support)
- **Advanced functions** (directory bookmarking, git workflows)
- **Eternal history** with timestamps
- **Base16 color schemes** integration

### 🖥️ **Terminal Setup** (Cross-Platform)
- **Kitty Terminal** - GPU-accelerated with ligatures
- **Tmux** - Terminal multiplexer with custom key bindings
- **Tmux Powerline** - Beautiful two-line status bar (macOS)
- **JetBrains Mono Nerd Font** - Programming font with icons

### 🔧 **Development Tools** (Cross-Platform)
- **AstroNvim** - Modern Neovim distribution
- **Git** - Enhanced with diff-so-fancy and custom aliases
- **Node.js** - Latest LTS via nvm
- **Python** - Latest stable via pyenv
- **Claude Code** - AI-powered coding assistant

### 📦 **Package Management**
- **macOS**: Homebrew with curated app list
- **Fedora Traditional**: dnf with Hyprland ecosystem packages
- **Fedora Atomic**: rpm-ostree (system) + Flatpak (apps)
- **TPM** - Tmux plugin manager
- **Language Managers** - nvm, pyenv, pipx

### 🎨 **Applications**

#### macOS
- **Productivity**: Alfred, Todoist, Rectangle, Hammerspoon
- **Development**: Docker, Postman, VS Code alternatives
- **Communication**: Slack, WhatsApp
- **Creative**: Adobe Creative Cloud, Spotify

#### Linux (Hyprland Desktop)
- **Window Manager**: Hyprland (tiling + floating compositor)
- **Status Bar**: Waybar with modern theme
- **App Launcher**: rofi (Alfred replacement)
- **Wallpaper**: Variety + hyprpaper with automatic rotation
- **Screen Lock**: swaylock-effects with blur
- **Hotkeys**: swhkd (Hammerspoon replacement)
- **Icons**: Papirus + Papirus Dark themes

---

## 🔧 Installation

### 📋 Installation Options

The `install.sh` script provides several installation modes:

| Command | Description |
|---------|-------------|
| `./install.sh` | Full installation (default) |
| `./install.sh --reinstall` | Reinstall configurations only |
| `./install.sh --force` | Force reinstall without prompts |
| `./install.sh --uninstall` | Remove all configurations |
| `./install.sh --help` | Show all options |

### 🔄 Installation Process

#### 1. **Environment Validation**
- Checks for macOS compatibility
- Verifies required directories and files
- Validates system dependencies

#### 2. **Homebrew Setup**
- Installs Homebrew if not present
- Updates package lists
- Configures PATH for current session

#### 3. **Package Installation**
- **Formulas**: Development tools and utilities
- **Casks**: Desktop applications
- **Fonts**: Programming fonts with icon support

#### 4. **Configuration Linking**
- Creates symbolic links to configuration files
- Backs up existing configurations
- Sets up directory structure

#### 5. **Plugin Installation**
- Installs tmux plugin manager (TPM)
- Clones Base16 color schemes
- Sets up AstroNvim configuration

#### 6. **Language Setup**
- Installs latest Node.js LTS via nvm
- Installs latest Python via pyenv
- Configures default versions

#### 7. **Final Configuration**
- Links custom configurations
- Installs Claude Code CLI
- Completes environment setup

---

## 📁 Configuration Structure

### 🗂️ Directory Layout
```
~/.dotfiles/
├── 📄 README.md                    # This comprehensive guide
├── 🚀 install.sh                   # Automated installation script
├── 🚀 post-setup.sh                # Language environment setup script
├── 🔧 change-shell.sh              # Shell change helper script
├── 🙈 .gitignore                   # Git ignore rules
└── 📁 config/                      # Configuration files
    ├── 🐚 bash/                    # Bash shell configuration (Cross-Platform)
    │   ├── 📄 bash_profile         # Main bash profile
    │   ├── 📄 bash_profile_aliases # Command aliases (OS-aware)
    │   ├── 📄 bash_profile_functions # Custom functions
    │   ├── 📄 bash_profile_git     # Git-specific configurations
    │   ├── 📄 bash_profile_tools   # Tool integrations
    │   ├── 📄 bash_profile_local   # Local machine settings
    │   └── 📄 README.md            # Bash configuration guide
    ├── 🐱 kitty/                   # Kitty terminal configuration (Cross-Platform)
    │   ├── 📄 kitty.conf           # Terminal settings
    │   ├── 📄 sample.conf          # Sample configuration
    │   └── 📄 README.md            # Kitty user guide
    ├── 🖥️ tmux/                    # Tmux configuration (Cross-Platform)
    │   ├── 📄 tmux.conf            # Tmux settings
    │   ├── 📁 plugins/             # Tmux plugins
    │   └── 📄 README.md            # Tmux user guide
    ├── 🔋 tmux-powerline/          # Tmux powerline theme (macOS)
    │   ├── 📄 config.sh            # Powerline configuration
    │   ├── 📁 themes/              # Visual themes
    │   └── 📄 README.md            # Powerline guide
    ├── 🚀 nvim/                    # Neovim configuration (Cross-Platform)
    │   ├── 📄 polish.lua           # AstroNvim customizations
    │   ├── 📄 user.lua             # Plugin configurations
    │   └── 📄 README.md            # AstroNvim user guide
    ├── 🔨 hammerspoon/             # Hammerspoon automation (macOS)
    │   ├── 📄 init.lua             # Hotkey and automation config
    │   └── 📄 README.md            # Hammerspoon user guide
    ├── 🏙️ hyprland/                # Hyprland compositor (Linux)
    │   ├── 📄 hyprland.conf        # Window manager configuration
    │   └── 📄 README.md            # Hyprland user guide
    ├── 📊 waybar/                  # Status bar (Linux)
    │   ├── 📄 config               # Waybar configuration
    │   ├── 📄 style.css            # Modern theme styling
    │   └── 📄 README.md            # Waybar user guide  
    ├── 🚀 rofi/                    # App launcher (Linux)
    │   ├── 📄 config.rasi          # Rofi configuration and theme
    │   ├── 📁 scripts/             # Power menu and utilities
    │   └── 📄 README.md            # Rofi user guide
    ├── ⌨️ swhkd/                   # Global hotkeys (Linux)
    │   ├── 📄 swhkdrc              # Hotkey configuration
    │   └── 📄 README.md            # swhkd user guide
    ├── 🖼️ variety/                 # Wallpaper manager (Linux)
    │   ├── 📄 variety.conf         # Wallpaper rotation settings
    │   ├── 📁 scripts/             # Setup and utility scripts
    │   └── 📄 README.md            # Variety user guide
    ├── 🎨 hyprpaper/               # Wallpaper utility (Linux)
    │   ├── 📄 hyprpaper.conf       # Wallpaper display settings
    │   └── 📄 README.md            # Hyprpaper user guide
    ├── 🔒 swaylock/                # Screen locker (Linux)
    │   ├── 📄 config               # Lock screen configuration
    │   └── 📄 README.md            # Swaylock user guide
    └── 📄 gitconfig                # Git configuration (Cross-Platform)
```

### 🔗 Symlink Structure
After installation, configurations are linked to standard locations:

#### Cross-Platform
| Source | Target | Purpose |
|--------|--------|---------|
| `config/bash/bash_profile` | `~/.bash_profile` | Main bash configuration |
| `config/bash/bash_profile` | `~/.bashrc` | Bash initialization |
| `config/bash/` | `~/.config/bash/` | Bash configuration directory |
| `config/tmux/` | `~/.config/tmux/` | Tmux configuration |
| `config/kitty/` | `~/.config/kitty/` | Kitty terminal configuration |
| `config/gitconfig` | `~/.gitconfig` | Git configuration |
| `config/nvim/polish.lua` | `~/.config/nvim/lua/polish.lua` | Neovim customizations |
| `config/nvim/user.lua` | `~/.config/nvim/lua/plugins/user.lua` | Neovim plugins |

#### macOS Specific
| Source | Target | Purpose |
|--------|--------|---------|
| `config/hammerspoon/` | `~/.config/hammerspoon/` | Hammerspoon automation |

#### Linux Specific  
| Source | Target | Purpose |
|--------|--------|---------|
| `config/hyprland/` | `~/.config/hypr/` | Hyprland compositor |
| `config/waybar/` | `~/.config/waybar/` | Status bar |
| `config/rofi/` | `~/.config/rofi/` | App launcher |
| `config/swhkd/` | `/etc/swhkd/` | Global hotkeys |
| `config/variety/` | `~/.config/variety/` | Wallpaper manager |
| `config/swaylock/` | `~/.config/swaylock/` | Screen locker |

---

## 🛠️ Tools & Applications

### 🔧 Development Tools (Cross-Platform)
| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Bash** | Modern shell with enhancements | `config/bash/` |
| **Git** | Version control with aliases | `config/gitconfig` |
| **Tmux** | Terminal multiplexer | `config/tmux/` |
| **Neovim** | Modern text editor | `config/nvim/` |
| **Kitty** | GPU-accelerated terminal | `config/kitty/` |

### 🖥️ Desktop Environment Tools

#### macOS
| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Hammerspoon** | macOS automation and hotkeys | `config/hammerspoon/` |
| **Alfred** | App launcher and productivity | External app |
| **Rectangle** | Window management | External app |

#### Linux (Hyprland)
| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Hyprland** | Tiling Wayland compositor | `config/hyprland/` |
| **Waybar** | Status bar with system info | `config/waybar/` |
| **rofi** | App launcher (Alfred replacement) | `config/rofi/` |
| **swhkd** | Global hotkeys (Hammerspoon replacement) | `config/swhkd/` |
| **Variety** | Wallpaper manager with rotation | `config/variety/` |
| **hyprpaper** | Fast wallpaper utility | `config/hyprpaper/` |
| **swaylock** | Screen locker with effects | `config/swaylock/` |

### 📦 Package Managers
| Tool | Purpose | Auto-Setup |
|------|---------|-------------|
| **Homebrew** | macOS package manager | ✅ |
| **NVM** | Node.js version manager | ✅ |
| **Pyenv** | Python version manager | ✅ |
| **TPM** | Tmux plugin manager | ✅ |

### 🎨 Applications Installed
#### **Productivity**
- **Alfred** - Productivity app and launcher
- **Todoist** - Task management
- **Rectangle** - Window management

#### **Development**
- **Postman** - API testing tool
- **Claude** - AI coding assistant
- **1Password** - Password manager

> **Note**: Docker is currently disabled in the installation due to package conflicts. Install manually with `brew install --cask docker` if needed.

#### **Communication**
- **Slack** - Team communication
- **WhatsApp** - Messaging

#### **Creative & Media**
- **Adobe Creative Cloud** - Design tools
- **Spotify** - Music streaming
- **Notion** - Note-taking and productivity

#### **Utilities**
- **Google Chrome** - Web browser
- **TlDr** - Simplified man pages
- **Bottom** - System monitor
- **Lazygit** - Git TUI
- **Ripgrep** - Fast text search
- **fd** - Fast file finder
- **Tree-sitter** - Parser generator
- **Go** - Programming language
- **gdu** - Disk usage analyzer

---

## 🎨 Customization

### 🎨 Color Schemes
The setup uses **Base16** color schemes for consistent theming:
- **Location**: `~/.config/base16-shell/`
- **Usage**: `base16_<theme-name>` in terminal
- **Integration**: Works with tmux, vim, and shell

### 🔧 Personal Customizations
Create machine-specific settings:
```bash
# Edit local bash settings
nvim ~/.config/bash/bash_profile_local

# Add personal aliases, functions, exports
export MY_CUSTOM_VAR="value"
alias my_alias="command"
```

### 🎨 Theme Customization
#### Tmux Powerline
```bash
# Edit powerline configuration
nvim ~/.config/tmux-powerline/config.sh

# Customize segments, colors, and layout
```

#### Kitty Terminal
```bash
# Edit kitty configuration
nvim ~/.config/kitty/kitty.conf

# Customize fonts, colors, and behavior
```

### 🔌 Plugin Management
#### Tmux Plugins
```bash
# Inside tmux session
` I    # Install plugins
` U    # Update plugins
` alt + u    # Uninstall plugins
```

#### Neovim Plugins
```bash
# Inside neovim
:Lazy    # Open plugin manager
```

---

## 🔄 Management

### 🔄 Updating Configurations
```bash
# Navigate to dotfiles directory
cd ~/.dotfiles

# Pull latest changes
git pull

# Reinstall configurations
./install.sh --reinstall
```

### 🔄 Backup & Restore
The installation script automatically creates backups:
- **Format**: `filename.backup.YYYYMMDD_HHMMSS`
- **Location**: Same directory as original file
- **Restore**: Manually copy backup over current file

### 🔄 Selective Updates
```bash
# Update only specific configurations
./install.sh --reinstall

# Force update without prompts
./install.sh --force

# Update specific tools
brew update && brew upgrade
```

---

## 💡 Pro Tips

### 🚀 Productivity Shortcuts

#### Quick Navigation
```bash
# Use directory bookmarking
mark project          # Bookmark current directory
j project            # Jump to bookmarked directory
marks                # List all bookmarks
```

#### Git Workflow
```bash
# Quick commit and push
gup "commit message"  # Commit and push in one command

# Branch management
gcg feature          # Checkout first branch matching "feature"
gbcp                 # Copy current branch name to clipboard
```

#### Tmux Workflow
```bash
# Create development session
tmux new-session -s dev -d
tmux send-keys -t dev 'cd ~/project && nvim' Enter
tmux split-window -t dev -h
tmux send-keys -t dev 'npm run dev' Enter
tmux attach -t dev
```

### 🔧 Advanced Usage

#### Multi-Machine Setup
```bash
# Clone on different machines
git clone https://github.com/cintron/.dotfiles.git

# Customize per machine
echo "export HOST_SPECIFIC_VAR='value'" >> ~/.config/bash/bash_profile_local
```

#### Custom Tool Integration
```bash
# Add new tools to bash_profile_tools
echo 'eval "$(tool init bash)"' >> ~/.config/bash/bash_profile_tools

# Reload configuration
sb  # Source bash profile
```

### 🎯 Development Workflow

#### Project Setup
1. **Create tmux session** for project
2. **Use directory bookmarking** for quick access
3. **Leverage git aliases** for efficient version control
4. **Use kitty tabs** for different contexts

#### Multi-Environment Development
- **Local**: Full development environment
- **Remote**: Use kitty's SSH integration
- **Containers**: Docker development workflow

---

## 🔍 Troubleshooting

### Common Issues

#### **Homebrew Installation Fails**
```bash
# Check system compatibility
uname -a

# Install command line tools
xcode-select --install

# Try manual installation
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### **Bash Not Default Shell**
```bash
# Add homebrew bash to allowed shells
sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'

# Change default shell
chsh -s /opt/homebrew/bin/bash

# Verify change
echo $SHELL
```

#### **Tmux Plugins Not Loading**
```bash
# Check tpm installation
ls -la ~/.config/tmux/plugins/tpm

# Reinstall tpm
rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install plugins in tmux
` I
```

#### **Neovim Configuration Issues**
```bash
# Check AstroNvim installation
ls -la ~/.config/nvim

# Verify symlinks
ls -la ~/.config/nvim/lua/polish.lua
ls -la ~/.config/nvim/lua/plugins/user.lua

# Reinstall AstroNvim
./install.sh --reinstall
```

#### **Font Issues**
```bash
# List installed fonts
brew list --cask | grep font

# Install missing fonts
brew install --cask font-jetbrains-mono-nerd-font

# Check font in terminal
echo "Testing font: 🔥 →  ←  ↑  ↓"
```

### 🔧 Maintenance

#### **Regular Updates**
```bash
# Update system
brew update && brew upgrade

# Update configurations
cd ~/.dotfiles && git pull && ./install.sh --reinstall

# Update language versions
nvm install --lts
pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1
```

#### **Cleanup**
```bash
# Clean homebrew
brew cleanup

# Clean old backups
find ~ -name "*.backup.*" -type f -mtime +30 -delete

# Clean tmux sessions
tmux list-sessions | grep -v attached | cut -d: -f1 | xargs -t -n1 tmux kill-session -t
```

---

## 🤝 Contributing

### 🔧 Adding New Tools
1. **Update `install.sh`** with new package
2. **Add configuration** to appropriate `config/` directory
3. **Update README** with new tool documentation
4. **Test installation** on clean system

### 🎨 Customizing Configurations
1. **Fork repository** for personal modifications
2. **Create feature branch** for changes
3. **Test thoroughly** before merging
4. **Document changes** in README

---

## 📚 Additional Resources

### 📖 Configuration Guides

#### Cross-Platform
- **[Bash Configuration Guide](config/bash/README.md)** - Complete bash setup
- **[Kitty Terminal Guide](config/kitty/README.md)** - Terminal customization
- **[Tmux User Guide](config/tmux/README.md)** - Terminal multiplexer
- **[AstroNvim Guide](config/nvim/README.md)** - Neovim configuration

#### macOS Specific
- **[Tmux Powerline Guide](config/tmux-powerline/README.md)** - Status line setup
- **[Hammerspoon Guide](config/hammerspoon/README.md)** - macOS automation setup

#### Linux Specific
- **[Hyprland Guide](config/hyprland/README.md)** - Window manager setup
- **[Waybar Guide](config/waybar/README.md)** - Status bar configuration
- **[Rofi Guide](config/rofi/README.md)** - App launcher setup
- **[swhkd Guide](config/swhkd/README.md)** - Global hotkey configuration
- **[Variety Guide](config/variety/README.md)** - Wallpaper management
- **[Hyprpaper Guide](config/hyprpaper/README.md)** - Wallpaper utility
- **[Swaylock Guide](config/swaylock/README.md)** - Screen locker

### 🔗 External Resources

#### Cross-Platform
- **[Base16 Colors](https://github.com/chriskempson/base16)** - Color schemes
- **[AstroNvim Documentation](https://astronvim.github.io/)** - Neovim distribution
- **[Tmux Wiki](https://github.com/tmux/tmux/wiki)** - Terminal multiplexer

#### macOS
- **[Homebrew Documentation](https://brew.sh/)** - Package manager

#### Linux
- **[Hyprland Wiki](https://wiki.hyprland.org/)** - Hyprland compositor
- **[Waybar Wiki](https://github.com/Alexays/Waybar/wiki)** - Status bar
- **[Arch Wiki Wayland](https://wiki.archlinux.org/title/Wayland)** - Wayland info
- **[swhkd Repository](https://github.com/waycrate/swhkd)** - Hotkey daemon

---

## 🎯 Quick Start Guide

### After Installation

#### Both Systems
1. **Restart terminal** or run `source ~/.bash_profile`
2. **Verify installations**: Check that `nvim`, `git`, `tmux` work
3. **Explore aliases**: Try `la`, `gs`, `pbc`/`pbp` (clipboard)

#### macOS Users
4. **Launch applications**: Open Alfred, Rectangle, Hammerspoon
5. **Grant permissions**: Allow Hammerspoon accessibility access
6. **Set defaults**: Make Kitty your default terminal

#### Linux Users  
4. **Start Hyprland**: Select Hyprland from your display manager
5. **Learn shortcuts**: 
   - `Super + Space` → App launcher
   - `Super + Return` → Terminal
   - `Super + L` → Lock screen
   - `Super + Alt + N/P` → Cycle wallpapers
6. **Check status**: Verify waybar appears at top

> **💡 Tip**: Use the individual README files in each config directory for detailed usage instructions and customization options!

---

*Last updated: July 2025*
