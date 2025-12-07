# 🚀 AstroNvim Configuration - User Guide

> **A comprehensive guide to using your customized AstroNvim setup**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [⌨️ Essential Keymaps](#️-essential-keymaps)
- [🎯 Core Features](#-core-features)
- [💻 Development Workflow](#-development-workflow)
- [🛠️ Advanced Features](#️-advanced-features)
- [🔍 Troubleshooting](#-troubleshooting)
- [📚 Reference](#-reference)

---

## 🔧 Quick Start

### First-Time Setup

1. **Install AstroNvim** (if not already installed):
   ```bash
   git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
   ```

2. **Symlink your config**:
   ```bash
   ln -sf ~/.dotfiles/config/nvim/polish.lua ~/.config/nvim/lua/polish.lua
   ln -sf ~/.dotfiles/config/nvim/user.lua ~/.config/nvim/lua/plugins/user.lua
   ```

3. **Launch and setup**:
   ```bash
   nvim
   ```
   - Plugins will auto-install on first launch
   - Run `:Mason` to verify language servers
   - For Copilot: `:Copilot auth`

### 🎨 Current Theme
- **Active**: `base16-darkmoss` colorscheme
- **Available**: `base16-*` (via base16-nvim), `material`, `minimal`

---

## ⌨️ Essential Keymaps

> **Note**: `<leader>` key is `Space` by default in AstroNvim

### 📁 File Operations
| Keymap | Description |
|--------|-------------|
| `<leader>w` | Save file |
| `<leader>W` | Save with sudo |
| `<leader>q` | Quit |
| `<leader>Q` | Force quit |
| `<leader>x` | Save and quit |
| `<leader>X` | Save and quit with sudo |

### 📋 Clipboard Operations
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>y` | Normal/Visual | Copy to system clipboard |
| `<leader>yy` | Normal | Copy line to system clipboard |
| `<leader>Y` | Normal | Copy from cursor to end of line |
| `<leader>p` | Normal/Visual | Paste from system clipboard |
| `<leader>P` | Normal/Visual | Paste before cursor |
| `<leader>pp` | Normal | Paste with auto-indent |
| `<leader>PP` | Normal | Paste before with auto-indent |

### 🗂️ Buffer Navigation
| Keymap | Description |
|--------|-------------|
| `<leader>j` | Previous buffer |
| `<leader>k` | Next buffer |
| `<leader>bj` | Next buffer (explicit) |
| `<leader>bk` | Previous buffer (explicit) |
| `<leader>bd` | Delete buffer |
| `<leader>bl` | List all buffers |

### 🪟 Window Navigation
| Keymap | Description |
|--------|-------------|
| `<C-h>` | Move to left window |
| `<C-j>` | Move to window below |
| `<C-k>` | Move to window above |
| `<C-l>` | Move to right window |

### 🏃 Fast Scrolling
| Keymap | Description |
|--------|-------------|
| `<M-j>` / `∆` | Scroll down 5 lines |
| `<M-k>` / `˚` | Scroll up 5 lines |
| `<M-J>` / `Ô` | Scroll down 15 lines |
| `<M-K>` / `` | Scroll up 15 lines |

### 🔍 Search & Folding
| Keymap | Description |
|--------|-------------|
| `<leader>h` | Toggle search highlight |
| `\` | Toggle fold (or insert space) |
| `\` (Visual) | Create fold from selection |

### 🗑️ Smart Deletion
| Keymap | Description |
|--------|-------------|
| `dw` | Delete word backwards |
| `<leader>d` | Delete without yanking |
| `x` | Delete character without yanking |

---

## 🎯 Core Features

### 🎨 Mini.nvim Plugins

#### Surround (`mini.surround`)
| Keymap | Description |
|--------|-------------|
| `sa` | Add surrounding |
| `sd` | Delete surrounding |
| `sr` | Replace surrounding |
| `sf` | Find right surrounding |
| `sF` | Find left surrounding |

#### Split/Join (`mini.splitjoin`)
| Keymap | Description |
|--------|-------------|
| `gS` | Toggle split/join lines |

#### Move (`mini.move`)
| Keymap | Description |
|--------|-------------|
| `<C-M-h>` | Move text/selection left |
| `<C-M-j>` | Move text/selection down |
| `<C-M-k>` | Move text/selection up |
| `<C-M-l>` | Move text/selection right |

### 🔍 Snacks Picker
- **Enhanced picker UI** with telescope icon 🔭
- **Layout**: Preview on top, results below
- **Size**: 85% width, 90% height
- **Access**: Use AstroNvim's built-in picker commands

---

## 💻 Development Workflow

### 🛠️ Language Server Support

**Auto-installed via Mason**:
- **Frontend**: TypeScript, JavaScript, HTML, CSS, Tailwind
- **Backend**: Python, Ruby, Bash
- **DevOps**: Docker, Terraform, YAML
- **Documentation**: Markdown, JSON

### 🐛 Debugging

#### Python & JavaScript/TypeScript Debugging
| Keymap | Description |
|--------|-------------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue execution |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |
| `<leader>dl` | Run last |
| `<leader>du` | Toggle debug UI |
| `<leader>dt` | Terminate session |

#### Debugging Workflow
1. **Set breakpoints** with `<leader>db`
2. **Start debugging** with `<leader>dc`
3. **Step through code** with `<leader>di/do/dO`
4. **UI opens automatically** when debugging starts

### 🧪 Testing

#### Test Commands
| Keymap | Description |
|--------|-------------|
| `<leader>tt` | Run test under cursor |
| `<leader>tf` | Run all tests in file |
| `<leader>td` | Debug test under cursor |
| `<leader>ts` | Stop running tests |
| `<leader>ta` | Attach to test process |

#### Testing Workflow
1. **Single test**: `<leader>tt` on test function
2. **File tests**: `<leader>tf` anywhere in test file
3. **Debug mode**: `<leader>td` to debug specific test

### 🐳 Docker Development

**Dev Container Support**:
- **Automatic detection** of `.devcontainer/devcontainer.json`
- **Full LSP support** inside containers
- **Transparent editing** with complete IDE features

---

## 🛠️ Advanced Features

### 🤖 AI Integration (GitHub Copilot)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-g>` | Insert | Accept suggestion |
| `<C-j>` | Insert | Next suggestion |
| `<C-k>` | Insert | Previous suggestion |
| `<C-o>` | Insert | Dismiss suggestions |

#### AI Workflow
1. **Start typing** - suggestions appear automatically
2. **Accept** with `<C-g>` or cycle through with `<C-j/k>`
3. **Dismiss** unwanted suggestions with `<C-o>`

### 🎨 Custom Commands

| Command | Description |
|---------|-------------|
| `:Q` | Force quit |
| `:W` | Save with sudo |
| `:X` | Save and quit with sudo |

### ⚙️ Special Settings

- **Clipboard**: Disabled by default, use `<leader>y/p` for system clipboard
- **Line numbers**: Absolute (not relative)
- **Tabs**: 2 spaces, expanded
- **Mouse**: Enabled
- **Incremental search**: Enabled

---

## 🔍 Troubleshooting

### Common Issues

#### Clipboard not working
- **Solution**: Use `<leader>y` and `<leader>p` instead of default `y` and `p`
- **Why**: Clipboard integration is intentionally disabled for better performance

#### Language server not starting
1. **Check Mason**: Run `:Mason` to verify installation
2. **Restart**: `:LspRestart` to restart language server
3. **Reinstall**: Use Mason to reinstall the language server

#### Debugging not working
- **Python**: Ensure `debugpy` is installed in your Python environment
- **JavaScript**: Verify Node.js is installed and accessible
- **General**: Check `:checkhealth` for diagnostic information

#### Copilot not working
1. **Authenticate**: Run `:Copilot auth`
2. **Check status**: `:Copilot status`
3. **Restart**: `:Copilot restart`

### Performance Tips

- **Large files**: Use `<leader>h` to toggle search highlighting
- **Folding**: Use `\` to fold large sections
- **Buffers**: Use `<leader>bd` to close unused buffers

---

## 📚 Reference

### File Structure
```
~/.dotfiles/config/nvim/
├── polish.lua          # Settings, keymaps, and customizations
├── user.lua            # Plugin configurations
└── README.md           # This user guide
```

### Key Configuration Files

#### `polish.lua`
- **Settings**: Clipboard, colors, indentation
- **Keymaps**: All custom key mappings
- **Commands**: Custom user commands

#### `user.lua`  
- **Plugins**: All plugin specifications
- **LSP**: Language server configurations
- **Debugging**: DAP and testing setup

### Plugin Categories

| Category | Plugins |
|----------|---------|
| **Mini plugins** | surround, move, splitjoin, snippets |
| **Language** | Mason, LSP servers, Treesitter |
| **Debugging** | nvim-dap, dap-ui, dap-python |
| **Testing** | neotest, neotest-python, neotest-jest |
| **AI** | GitHub Copilot |
| **Docker** | nvim-dev-container |
| **Themes** | minimal, base16, material |

### Getting Help

- **Which-key**: Press `<leader>` to see available commands
- **AstroNvim docs**: Built-in help system
- **Plugin docs**: `:help <plugin-name>`
- **Health check**: `:checkhealth`

---

> **💡 Pro Tip**: Press `<leader>` at any time to see all available keybindings through the which-key interface!

**Happy coding!** 🎉