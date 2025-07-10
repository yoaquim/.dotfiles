# 🐚 Bash Configuration - User Guide

> **A comprehensive guide to your customized bash setup with aliases, functions, and tools**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [📁 File Structure](#-file-structure)
- [⚙️ Core Settings](#️-core-settings)
- [🔀 Aliases](#-aliases)
- [🛠️ Functions](#️-functions)
- [🌳 Git Workflow](#-git-workflow)
- [📦 Tool Integration](#-tool-integration)
- [💡 Pro Tips](#-pro-tips)

---

## 🔧 Quick Start

### Setup Instructions

1. **Symlink the profile**:
   ```bash
   ln -sf ~/.dotfiles/config/bash/bash_profile ~/.bash_profile
   ```

2. **Reload your shell**:
   ```bash
   source ~/.bash_profile
   # or use the alias:
   sb
   ```

3. **Verify setup**:
   ```bash
   echo $PS1  # Should show custom prompt
   alias | grep "alias"  # Should show custom aliases
   ```

---

## 📁 File Structure

| File | Purpose |
|------|---------|
| `bash_profile` | Main profile that sources all other files |
| `bash_profile_aliases` | All command aliases |
| `bash_profile_functions` | Custom bash functions |
| `bash_profile_git` | Git-specific aliases and functions |
| `bash_profile_tools` | Tool integrations (nvm, pyenv, etc.) |
| `bash_profile_local` | Local machine-specific settings |

---

## ⚙️ Core Settings

### 🎨 Prompt & Colors
- **Custom PS1**: Shows current directory and git branch
- **Colors**: Full truecolor support (`COLORTERM=truecolor`)
- **Base16 Shell**: Integrated color scheme support

### 📚 History Configuration
- **Eternal History**: No size limits (`HISTFILESIZE=` `HISTSIZE=`)
- **Timestamps**: Each command timestamped (`HISTTIMEFORMAT='[%F %T] '`)
- **Immediate Write**: Commands written to history immediately
- **File Location**: `~/.bash_eternal_history`

### 🔧 Shell Options
- **Vi Mode**: `set -o vi` for vim-style editing
- **Globstar**: `shopt -s globstar` for `**` pattern matching
- **History Append**: `shopt -s histappend` to preserve history
- **Command History**: `shopt -s cmdhist` for multiline commands

---

## 🔀 Aliases

### 📋 Essential Shortcuts
| Alias | Command | Description |
|-------|---------|-------------|
| `c`, `cl` | `clear` | Clear terminal |
| `v` | `vim` | Open vim |
| `nv`, `av` | `nvim` | Open neovim |
| `t` | `touch` | Create file |
| `sb` | `source ~/.bash_profile` | Reload bash config |

### 📂 File Operations
| Alias | Command | Description |
|-------|---------|-------------|
| `l`, `ll` | `ls -l` | Long listing |
| `la` | `ls -la` | Show all files |
| `lh` | `ls -lh` | Human readable sizes |
| `lah`, `lha` | `ls -lah` | All files, human readable |
| `l1`, `la1` | `ls -lh1`, `ls -lah1` | Single column |
| `rmd` | `rm -rf` | Remove directory |

### 🧭 Navigation
| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up one directory |
| `...` | `cd -` | Go to previous directory |
| `cd.` | `cd ~/.dotfiles` | Go to dotfiles |
| `cdv` | `cd ~/.vim` | Go to vim config |
| `cdd` | `cd ~/Desktop/` | Go to desktop |
| `cdb` | `cd ~/Dropbox/` | Go to Dropbox |
| `cdp` | `cd ~/Projects/` | Go to projects |
| `cds` | `cd ~/Scratches/` | Go to scratches |

### 📋 Clipboard
| Alias | Command | Description |
|-------|---------|-------------|
| `pbc` | `pbcopy` | Copy to clipboard |
| `pbp` | `pbpaste` | Paste from clipboard |
| `cwd` | `pwd \| pbcopy` | Copy current directory path |
| `lcp` | `xclip -sel clip` | Linux clipboard copy |

### 🔧 Configuration Files
| Alias | Command | Description |
|-------|---------|-------------|
| `vb` | `nvim ~/.bash_profile` | Edit bash profile |
| `vbf` | `nvim ~/.config/bash/bash_profile_functions` | Edit functions |
| `vbt` | `nvim ~/.config/bash/bash_profile_tools` | Edit tools |
| `vbg` | `nvim ~/.config/bash/bash_profile_git` | Edit git config |
| `vbl` | `nvim ~/.config/bash/bash_profile_local` | Edit local config |
| `vba` | `nvim ~/.config/bash/bash_profile_aliases` | Edit aliases |
| `vk` | `nvim ~/.config/kitty/kitty.conf` | Edit kitty config |
| `vnv`, `nvc` | `nvim ~/.config/nvim` | Edit neovim config |
| `vt` | `nvim ~/.config/tmux/tmux.conf` | Edit tmux config |
| `vg` | `nvim ~/.gitconfig` | Edit git config |
| `vetc` | `sudo nvim /etc/hosts` | Edit hosts file |

### 🐳 Development Tools
| Alias | Command | Description |
|-------|---------|-------------|
| `tm` | `tmux` | Start tmux |
| `tml` | `tmux ls` | List tmux sessions |
| `tma` | `tmux attach -t` | Attach to session |
| `tmk` | `tmux kill-session -t` | Kill session |
| `dcp` | `docker compose` | Docker compose |
| `npms` | `npm -s` | NPM silent mode |
| `flush` | DNS cache flush | Flush DNS cache |

---

## 🛠️ Functions

### 📁 Directory Navigation

#### `up [number]` (alias: `ff`)
Navigate up multiple directory levels:
```bash
up 3      # Go up 3 directories
ff 2      # Same as above (alias)
up        # Go up 1 directory (same as ..)
```

#### Directory Bookmarking System
| Function | Usage | Description |
|----------|-------|-------------|
| `mark <name>` | `mark project` | Bookmark current directory |
| `jump <name>` | `jump project` | Jump to bookmarked directory |
| `j <name>` | `j project` | Jump (alias) |
| `marks` | `marks` | List all bookmarks |
| `unmark <name>` | `unmark project` | Remove bookmark |

**Example Workflow**:
```bash
cd ~/Projects/my-app
mark myapp               # Bookmark this location
cd /somewhere/else
j myapp                 # Jump back to ~/Projects/my-app
marks                   # See all bookmarks
unmark myapp            # Remove bookmark
```

### 🔧 System Functions

#### `toggle_hidden()`
Toggle visibility of hidden files in macOS Finder:
```bash
toggle_hidden           # Show/hide dotfiles in Finder
```

---

## 🌳 Git Workflow

### 📝 Basic Git Aliases
| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Show status |
| `ga` | `git add` | Add files |
| `gall` | `git add --all` | Add all files |
| `gau` | `git add -u` | Add tracked files |
| `gap` | `git add -p` | Interactive add |
| `gcomm` | `git commit -m` | Commit with message |
| `gp` | `git pull` | Pull changes |
| `gpr` | `git pull --rebase` | Pull with rebase |
| `gf` | `git fetch` | Fetch changes |

### 🌿 Branch Management
| Alias | Command | Description |
|-------|---------|-------------|
| `gb` | `git branch` | List branches |
| `gco` | `git checkout` | Checkout branch |
| `gcb` | `git checkout -b` | Create new branch |
| `gbcp` | Copy branch name | Copy current branch name |

### 🔄 Advanced Git Operations
| Alias | Command | Description |
|-------|---------|-------------|
| `gr` | `git reset` | Reset changes |
| `grh` | `git reset --hard` | Hard reset |
| `gam` | `git commit --amend` | Amend last commit |
| `gamn` | `git commit --amend --no-edit` | Amend without editing |
| `gd` | `git diff` | Show differences |
| `gds` | `git diff --staged` | Show staged differences |
| `gfd` | Show files in last commit | List changed files |
| `glog` | `git plog` | Pretty log (custom alias) |

### 🔧 Git Functions

#### `gbu()` - Set Branch Upstream
Set tracking info for current branch:
```bash
gbu                     # Set upstream to origin/current-branch
```

#### `gcg <pattern>` - Grep Checkout
Checkout first branch matching pattern:
```bash
gcg feature            # Checkout first branch containing "feature"
```

#### `gcrb <name>` - Remote Run Branch
Create branch with `remote-run/` prefix:
```bash
gcrb testing           # Creates "remote-run/testing"
```

#### `gpush [options]` - Smart Push
Push current branch to origin:
```bash
gpush                  # Push current branch
gpush --force          # Push with force
```

#### `gup <message>` - Commit and Push
Commit and push in one command:
```bash
gup "Fix bug in login"  # Commit and push
```

#### `roob [source_branch]` - Rebase on Branch
Rebase current branch on another branch:
```bash
roob master            # Rebase current branch on master
roob                   # Rebase on default branch
```

---

## 📦 Tool Integration

### 🟢 Node Version Manager (NVM)
- **Auto-loaded**: NVM available in all shells
- **Directory**: `~/.nvm`
- **Completion**: Tab completion enabled

### 🐍 Python Environment Manager (pyenv)
- **Auto-loaded**: pyenv available in all shells
- **Directory**: `~/.pyenv`
- **Integration**: Automatic Python version switching

### 📁 Directory Environment (direnv)
- **Auto-loaded**: Environment variables from `.envrc`
- **Integration**: Automatic activation/deactivation

### 🌐 Ngrok
- **Completion**: Tab completion for ngrok commands
- **Integration**: Auto-loaded if installed

---

## 💡 Pro Tips

### 🔥 Productivity Shortcuts
1. **Use bookmarks** for frequently accessed directories:
   ```bash
   mark work && cd /long/path/to/somewhere && j work
   ```

2. **Leverage git functions** for faster workflow:
   ```bash
   gup "Quick fix"        # Commit and push
   gcg feat              # Quick branch switching
   ```

3. **Edit configs quickly**:
   ```bash
   vba                   # Edit aliases
   vbf                   # Edit functions
   sb                    # Reload immediately
   ```

### 🎯 Advanced Usage

#### Custom Prompt Information
The prompt shows:
- **Current directory** (colored green)
- **Git branch** (if in git repo)
- **Username** (colored cyan)

#### History Search
With vi mode enabled:
- `Ctrl+R` - Reverse search
- `ESC` then `/` - Search in vi mode
- `j/k` - Navigate history in vi mode

#### Tab Completion
- **Mark completion**: `j <TAB>` shows available bookmarks
- **Git completion**: Git commands have full tab completion
- **Tool completion**: NVM, pyenv, direnv all support completion

### 🔧 Customization

#### Adding Personal Aliases
Edit `bash_profile_local` for machine-specific settings:
```bash
vbl                    # Edit local config
# Add your personal aliases here
```

#### Environment Variables
Add to `bash_profile_local`:
```bash
export MY_VAR="value"
export PATH="$PATH:/my/custom/path"
```

---

> **💡 Pro Tip**: Use `sb` after making any configuration changes to reload your bash profile instantly!

**Happy bash-ing!** 🚀