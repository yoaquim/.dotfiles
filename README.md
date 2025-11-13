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
    ├── 🐚 bash/                    # Bash shell configuration
    │   ├── 📄 bash_profile         # Main bash profile
    │   ├── 📄 bash_profile_aliases # Command aliases
    │   ├── 📄 bash_profile_functions # Custom functions
    │   ├── 📄 bash_profile_git     # Git-specific configurations
    │   ├── 📄 bash_profile_tools   # Tool integrations
    │   ├── 📄 bash_profile_local   # Local machine settings
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
    ├── 🤖 claude/                  # Claude Code configuration
    │   ├── 📄 setup.sh             # Claude setup script
    │   ├── 📁 commands/            # Custom slash commands
    │   └── 📁 workflow/            # Universal workflows and templates
    │       ├── 📄 README.md        # Complete workflow documentation
    │       ├── 📁 sops/            # Standard operating procedures
    │       └── 📁 templates/       # Project initialization templates
    └── 📄 gitconfig                # Git configuration
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
| `config/hammerspoon/` | `~/.config/hammerspoon/` | Hammerspoon automation |
| `claude/` | `~/.claude/` | Claude Code global configuration |

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

This dotfiles setup includes a **custom Claude Code configuration** that provides standardized workflows, slash commands, and documentation templates for all projects.

### 🎯 What's Included

**Custom Slash Commands** (available globally in any project):
- `/init-project` - Initialize `.agent/` documentation system for new/existing projects
- `/feature` - Define WHAT to build (feature requirements with EARS format)
- `/plan-task` - Plan HOW to build it (technical implementation, auto-detects last feature)
- `/implement-task` - Implement documented tasks with git workflow
- `/test-task` - Test implementations with automated and manual verification
- `/complete-task` - Finalize tasks with documentation updates
- `/fix-bug` - Intelligent bug fixing (quick hotfix or full bug task workflow)
- `/document-issue` - Document known issues for future reference
- `/status` - Comprehensive project status report
- `/review-docs` - Review documentation for accuracy and consistency
- `/update-doc` - Update project documentation

**Universal SOPs** (Standard Operating Procedures):
- Git workflow and branching strategies
- Testing principles and best practices
- Documentation standards
- Project structure conventions

**Project Templates**:
- `.agent/` directory structure templates
- Task documentation templates
- System documentation templates
- Automatic cross-project known-issues search

### ⚙️ Setup

The Claude configuration is automatically symlinked during dotfiles installation:

```bash
# Symlink created by install.sh
~/.claude → ~/.dotfiles/claude/
```

All slash commands and workflows are immediately available in any project after installation.

### 🚀 Quick Start

**Initialize a new project:**
```bash
# In any project directory
/init-project
```

This creates a complete `.agent/` documentation system with:
- Project overview and architecture docs
- Feature requirements directory
- Task management system
- Known issues tracking
- References to universal SOPs

**Define and build a feature:**
```bash
/feature "asset upload"             # Define WHAT to build (user requirements)
/plan-task                          # Plan HOW to build (auto-uses last feature)
/implement-task                     # Implement the latest task
/test-task                          # Test the implementation
/complete-task                      # Finalize and document
```

**Quick feature (skip requirements):**
```bash
/plan-task "simple feature"         # Plan directly without requirements
/implement-task
```

**Quick bug fix:**
```bash
/fix-bug <bug description>          # Intelligently routes to hotfix or full workflow
```

**Check project status:**
```bash
/status                             # View tasks, health, and next steps
```

### 🎨 Customization

Since the configuration is symlinked from your dotfiles:

1. **Edit commands** in `~/.dotfiles/claude/commands/`
2. **Changes apply globally** to all projects immediately
3. **No need to restart** - just start a new Claude chat or invoke the command

Example - updating a slash command:
```bash
# Edit any slash command
nvim ~/.dotfiles/claude/commands/fix-bug.md

# Changes are immediately available in all projects
# (start new chat or type / to see updates)
```

### 📚 Documentation

For complete documentation on the workflow system, templates, and SOPs:

**→ See [claude/workflow/README.md](claude/workflow/README.md)**

This includes:
- Complete workflow system overview
- Template customization guide
- Universal SOPs documentation
- Cross-project features
- Maintenance and troubleshooting

### 🔧 Supported Languages & Tools

The slash commands support multi-language projects:
- **Python**: pytest, docker
- **JavaScript/Node**: npm, docker
- **Git**: All git operations
- **Docker**: Containerized workflows

Commands automatically detect and use the appropriate tools for your project.

### 💡 Key Features

**Cross-Project Search**: Search known-issues across all your projects to learn from past solutions

**Symlinked Architecture**: Edit once in dotfiles, applies everywhere instantly

**Standardized Naming**: Consistent lowercase directories, kebab-case files, numbered tasks (000-999)

**Git Integration**: Built-in git workflow support with branch management and commit helpers

**Multi-Language Support**: Works with Python, Node, Docker, and more

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
- **[Bash Configuration Guide](config/bash/README.md)** - Complete bash setup
- **[Kitty Terminal Guide](config/kitty/README.md)** - Terminal customization
- **[Tmux User Guide](config/tmux/README.md)** - Terminal multiplexer
- **[Tmux Powerline Guide](config/tmux-powerline/README.md)** - Status line setup
- **[AstroNvim Guide](config/nvim/README.md)** - Neovim configuration
- **[Hammerspoon Guide](config/hammerspoon/README.md)** - macOS automation setup
- **[Claude Code Workflow Guide](claude/workflow/README.md)** - AI coding workflow system

### 🔗 External Resources
- **[Homebrew Documentation](https://brew.sh/)** - Package manager
- **[Base16 Colors](https://github.com/chriskempson/base16)** - Color schemes
- **[AstroNvim Documentation](https://astronvim.github.io/)** - Neovim distribution
- **[Tmux Wiki](https://github.com/tmux/tmux/wiki)** - Terminal multiplexer

---

> **💡 Tip**: After installation, run `source ~/.bash_profile` or start a new terminal session to activate all configurations. Use the individual README files in each config directory for detailed usage instructions!

---

*Last updated: July 2025*
