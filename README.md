# 🏡 Dotfiles - Complete Development Environment Setup

> **A comprehensive, automated macOS development environment with modern tools and configurations**

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [⚡ What's Included](#-whats-included)
- [🔧 Installation](#-installation)
- [📁 Configuration Structure](#-configuration-structure)
- [🛠️ Tools & Applications](#️-tools--applications)
- [🎨 Customization](#-customization)
- [🤖 Claude Code Workflow](#-claude-code-workflow)
- [🔄 Management](#-management)
- [💡 Pro Tips](#-pro-tips)
- [🔍 Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Prerequisites
- **macOS** (this setup is designed for macOS only)
- **Command Line Tools** for Xcode
- **Internet connection** for downloading tools

### Three-Step Installation

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

#### Step 3: AstroNvim Setup (requires SSH keys)
```bash
# Setup AstroNvim for Neovim (requires SSH keys configured for GitHub)
bash ./setup-astronvim.sh
```

> **Note**: Step 3 requires SSH keys (`~/.ssh/git` and `~/.ssh/git.pub`) to be configured
> and added to your GitHub account. The script will check for these before proceeding.

### Manual Installation
```bash
# 1. Clone the repository
cd ~/
git clone https://github.com/yoaquim/.dotfiles.git

# 2. Run core installation script (use bash explicitly for colors)
cd ~/.dotfiles
bash ./install.sh

# 3. Setup language environments (use bash explicitly)
bash ./post-setup.sh

# 4. Setup AstroNvim (requires SSH keys for GitHub)
bash ./setup-astronvim.sh
```

---

## ⚡ What's Included

### 🐚 **Shell Environment**
- **Modern Bash** with vim-style editing
- **50+ custom aliases** for productivity
- **Advanced functions** (directory bookmarking, git workflows)
- **Eternal history** with timestamps
- **Base16 color schemes** integration

### 🖥️ **Terminal Setup**
- **Kitty Terminal** - GPU-accelerated with ligatures
- **Tmux** - Terminal multiplexer with custom key bindings
- **Tmux Powerline** - Beautiful two-line status bar
- **JetBrains Mono Nerd Font** - Programming font with icons

### 🔧 **Development Tools**
- **AstroNvim** - Modern Neovim distribution
- **Git** - Enhanced with git-delta and custom aliases
- **Node.js** - Latest LTS via nvm
- **Python** - Latest stable via pyenv
- **Claude Code** - AI-powered coding assistant with custom workflow

### 📦 **Package Management**
- **Homebrew** - Package manager with curated app list
- **TPM** - Tmux plugin manager
- **Language Managers** - nvm, pyenv, pipx

### 🎨 **Applications**
- **Productivity**: Alfred, Todoist, Rectangle, Hammerspoon
- **Development**: Docker, Postman, VS Code alternatives
- **Communication**: Slack, WhatsApp
- **Creative**: Adobe Creative Cloud, Spotify

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

#### 6. **Language Setup**
- Installs latest Node.js LTS via nvm
- Installs latest Python via pyenv
- Configures default versions

#### 7. **Final Configuration**
- Links custom configurations
- Installs Claude Code CLI
- Completes environment setup

#### 8. **Claude Code Setup** (separate script)
- Run `cd ~/.dotfiles/claude && ./setup.sh` after Claude Code is installed
- Symlinks skills, agents, practices, and settings into `~/.claude/`

#### 9. **AstroNvim Setup** (separate script)
- Run `bash ./setup-astronvim.sh` after SSH keys are configured
- Checks for SSH keys (`~/.ssh/git` and `~/.ssh/git.pub`)
- Clones AstroNvim template
- Links custom polish.lua and user.lua configurations

---

## 📁 Configuration Structure

### 🗂️ Directory Layout
```
~/.dotfiles/
├── 📄 README.md                    # This comprehensive guide
├── 🚀 install.sh                   # Automated installation script
├── 🚀 post-setup.sh                # Language environment setup script
├── 🚀 setup-astronvim.sh           # AstroNvim setup script (requires SSH)
├── 🔧 change-shell.sh              # Shell change helper script
├── 🙈 .gitignore                   # Git ignore rules
└── 📁 config/                      # Configuration files
    ├── 🐚 bash/                    # Bash shell configuration
    │   ├── 📄 bash_profile         # Main bash profile
    │   ├── 📄 bash_profile_aliases # Command aliases
    │   ├── 📄 bash_profile_functions # Custom functions
    │   ├── 📄 bash_profile_git     # Git-specific configurations
    │   ├── 📄 bash_profile_tools   # Tool integrations
    │   ├── 📄 bash_profile_ssh    # SSH agent configuration
    │   ├── 📄 bash_profile_local  # Local machine settings (not in git)
    │   └── 📄 README.md            # Bash configuration guide
    ├── 🐱 kitty/                   # Kitty terminal configuration
    │   ├── 📄 kitty.conf           # Terminal settings
    │   ├── 📄 sample.conf          # Sample configuration
    │   └── 📄 README.md            # Kitty user guide
    ├── 🖥️ tmux/                    # Tmux configuration
    │   ├── 📄 tmux.conf            # Tmux settings
    │   ├── 📁 plugins/             # Tmux plugins
    │   └── 📄 README.md            # Tmux user guide
    ├── 🔋 tmux-powerline/          # Tmux powerline theme
    │   ├── 📄 config.sh            # Powerline configuration
    │   ├── 📁 themes/              # Visual themes
    │   └── 📄 README.md            # Powerline guide
    ├── 🚀 nvim/                    # Neovim configuration
    │   ├── 📄 polish.lua           # AstroNvim customizations
    │   ├── 📄 user.lua             # Plugin configurations
    │   └── 📄 README.md            # AstroNvim user guide
    ├── 🔨 hammerspoon/             # Hammerspoon automation
    │   ├── 📄 init.lua             # Hotkey and automation config
    │   └── 📄 README.md            # Hammerspoon user guide
    ├── 🌐 rclone/                  # rclone cloud storage configuration
    │   ├── 📄 rclone.conf          # Remote config (no secrets)
    │   ├── 📄 mount-cave.sh        # Mount script
    │   ├── 📄 com.rclone.cave.plist # LaunchAgent for auto-mount
    │   └── 📄 README.md            # rclone setup guide
    ├── 🔐 ssh/                     # SSH configuration
    │   └── 📄 config               # SSH config file
    ├── 📁 git/                      # Git local configuration
    │   └── 📄 config.local         # Machine-specific git settings (not in git)
    └── 📄 gitconfig                # Git configuration
└── 📁 claude/                      # Claude Code global configuration
    ├── 📄 setup.sh                 # Claude setup script (symlinks into ~/.claude/)
    ├── 📄 settings.json            # Claude Code settings
    ├── 📁 agents/                  # Autonomous agent definitions
    │   ├── 📄 deck-runner.md       # Deck spec runner agent
    │   └── 📄 linear-runner.md     # Linear ticket runner agent
    ├── 📁 practices/               # Development practice guides
    │   ├── 📄 INDEX.md             # Practice index
    │   ├── 📄 django.md            # Django best practices
    │   ├── 📄 docker.md            # Docker best practices
    │   ├── 📄 react.md             # React best practices
    │   ├── 📄 tailwind.md          # Tailwind best practices
    │   └── 📄 tdd.md               # TDD best practices
    └── 📁 skills/                  # Custom Claude Code skills
        ├── 📁 setup/               # /setup — init project (CLAUDE.md, git, hooks, deps)
        ├── 📁 deck/                # /deck — spec, dispatch, status, accept, close
        └── 📁 dispatch/            # /dispatch — fetch Linear ticket, spawn runner
```

### 🔗 Symlink Structure
After installation, configurations are linked to standard locations:

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
| `config/hammerspoon/` | `~/.hammerspoon/` | Hammerspoon automation |
| `config/rclone/` | `~/.config/rclone/` | rclone cloud storage |
| `config/ssh/config` | `~/.ssh/config` | SSH configuration |
| `claude/skills/` | `~/.claude/skills/` | Claude Code skills (via `claude/setup.sh`) |
| `claude/agents/` | `~/.claude/agents/` | Claude Code agents (via `claude/setup.sh`) |
| `claude/practices/` | `~/.claude/practices/` | Claude Code practices (via `claude/setup.sh`) |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings (via `claude/setup.sh`) |

---

## 🛠️ Tools & Applications

### 🔧 Development Tools
| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Bash** | Modern shell with enhancements | `config/bash/` |
| **Git** | Version control with aliases | `config/gitconfig` |
| **Tmux** | Terminal multiplexer | `config/tmux/` |
| **Neovim** | Modern text editor | `config/nvim/` |
| **Kitty** | GPU-accelerated terminal | `config/kitty/` |
| **Hammerspoon** | macOS automation and hotkeys | `config/hammerspoon/` |
| **Claude Code** | AI coding assistant with workflow | `claude/` |

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
- **Calibre** - E-book management
- **Quarto** - Scientific publishing
- **Folx** - Download manager
- **Hidden Bar** - Menu bar management

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

## 🤖 Claude Code Workflow

This dotfiles setup includes a **custom Claude Code configuration** with skills, agents, and development practice guides.

### 🎯 What's Included

**Skills** (custom slash commands, available globally):
- `/setup` — Initialize a project with CLAUDE.md, git, hooks, and dependencies
- `/deck` — Full feature lifecycle: spec, dispatch to runners, track status, accept, close
- `/dispatch` — Fetch a Linear ticket, discover context, and spawn an autonomous runner in an isolated worktree

**Agents** (autonomous runners for background work):
- **deck-runner** — Implements a spec from `.deck/` in an isolated worktree
- **linear-runner** — Implements a Linear ticket in an isolated worktree

**Practices** (development guides loaded as context):
- Django, Docker, React, Tailwind, TDD

### ⚙️ Setup

After dotfiles installation, run the Claude setup script to symlink skills, agents, practices, and settings into `~/.claude/`:

```bash
cd ~/.dotfiles/claude && ./setup.sh
```

This symlinks individual directories (`skills/`, `agents/`, `practices/`) and `settings.json` into `~/.claude/`.

### 🚀 Quick Start

**Initialize a new project:**
```bash
/setup
```

**Spec and build a feature (deck workflow):**
```bash
/deck spec <name>        # Spec out a feature
/deck dispatch <name>    # Spawn runner in isolated worktree
/deck status             # Check progress
/deck accept <name>      # E2E test acceptance criteria
/deck close <name>       # Merge, teardown, done
```

**Dispatch from Linear:**
```bash
/dispatch ENG-142        # Fetch ticket, discover context, spawn runner
/dispatch status         # Check all runners
/dispatch attach eng-142 # Interactive session in worktree
```

### 🎨 Customization

Since the configuration is symlinked from your dotfiles:

1. **Edit skills** in `~/.dotfiles/claude/skills/`
2. **Edit agents** in `~/.dotfiles/claude/agents/`
3. **Edit practices** in `~/.dotfiles/claude/practices/`
4. **Changes apply globally** to all projects immediately

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
git clone https://github.com/yoaquim/.dotfiles.git

# Customize per machine
echo "export HOST_SPECIFIC_VAR='value'" >> ~/.config/bash/bash_profile_local

# Machine-specific git settings (e.g., CodeRabbit machineId)
nvim ~/.config/git/config.local
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

#### **Neovim/AstroNvim Configuration Issues**
```bash
# Check AstroNvim installation
ls -la ~/.config/nvim

# Verify symlinks
ls -la ~/.config/nvim/lua/polish.lua
ls -la ~/.config/nvim/lua/plugins/user.lua

# Reinstall AstroNvim (requires SSH keys)
bash ./setup-astronvim.sh --force
```

#### **AstroNvim Clone Fails (SSH Issues)**
```bash
# Check SSH keys exist
ls -la ~/.ssh/git*

# Test GitHub SSH connection
ssh -T git@github.com

# If SSH is not configured, generate keys
ssh-keygen -t ed25519 -f ~/.ssh/git -C "your_email@example.com"

# Add key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/git

# Add public key to GitHub: https://github.com/settings/keys
cat ~/.ssh/git.pub

# Then retry AstroNvim setup
bash ./setup-astronvim.sh
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
- **[Bash Configuration Guide](config/bash/README.md)** - Complete bash setup
- **[Kitty Terminal Guide](config/kitty/README.md)** - Terminal customization
- **[Tmux User Guide](config/tmux/README.md)** - Terminal multiplexer
- **[Tmux Powerline Guide](config/tmux-powerline/README.md)** - Status line setup
- **[AstroNvim Guide](config/nvim/README.md)** - Neovim configuration
- **[Hammerspoon Guide](config/hammerspoon/README.md)** - macOS automation setup
- **[rclone Cave Guide](config/rclone/README.md)** - WebDAV cloud storage mount

### 🔗 External Resources
- **[Homebrew Documentation](https://brew.sh/)** - Package manager
- **[Base16 Colors](https://github.com/chriskempson/base16)** - Color schemes
- **[AstroNvim Documentation](https://astronvim.github.io/)** - Neovim distribution
- **[Tmux Wiki](https://github.com/tmux/tmux/wiki)** - Terminal multiplexer

---

> **💡 Tip**: After installation, run `source ~/.bash_profile` or start a new terminal session to activate all configurations. Use the individual README files in each config directory for detailed usage instructions!

---

*Last updated: March 2026*
