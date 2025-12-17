# Neovim Keybindings Cheat Sheet

## Core Navigation & Editing
| Keybinding | Action | Location |
|------------|--------|----------|
| `\` | Toggle fold (or insert space if not in fold) | polish.lua:117 |
| `\\` (visual) | Create fold | polish.lua:122 |
| `Ctrl + h/j/k/l` | Window navigation | polish.lua:134-137 |
| `dw` | Delete word backwards without yanking | polish.lua:62 |
| `x` | Delete character without yanking | polish.lua:65 |

## Leader Key Commands (`<leader>` = Space)

### File Operations
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>w` | Save file | polish.lua:88 |
| `<leader>W` | Save with sudo | polish.lua:89 |
| `<leader>q` | Quit | polish.lua:90 |
| `<leader>Q` | Force quit | polish.lua:91 |
| `<leader>x` | Save and exit | polish.lua:92 |
| `<leader>X` | Save and exit with sudo | polish.lua:93 |

### Editing & Deletion
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>d` | Delete without yanking | polish.lua:64 |
| `<leader>h` | Toggle search highlight | polish.lua:127 |

### Clipboard Operations
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>y` | Copy to system clipboard | polish.lua:72-74 |
| `<leader>yy` | Copy line to clipboard | polish.lua:74 |
| `<leader>Y` | Copy to end of line to clipboard | polish.lua:75 |
| `<leader>p` | Paste from clipboard | polish.lua:77-80 |
| `<leader>P` | Paste before cursor from clipboard | polish.lua:78-80 |
| `<leader>pp` | Paste and fix indentation | polish.lua:82 |
| `<leader>PP` | Paste before and fix indentation | polish.lua:83 |

### Buffer Management
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>j` | Previous buffer | polish.lua:147 |
| `<leader>k` | Next buffer | polish.lua:148 |
| `<leader>bj` | Next buffer (explicit) | polish.lua:142 |
| `<leader>bk` | Previous buffer (explicit) | polish.lua:143 |
| `<leader>bd` | Delete buffer | polish.lua:144 |
| `<leader>bl` | List buffers | polish.lua:145 |

## Fast Scrolling
| Keybinding | Action | Location |
|------------|--------|----------|
| `Alt + j` / `∆` | Scroll down 5 lines | polish.lua:102-110 |
| `Alt + k` / `˚` | Scroll up 5 lines | polish.lua:103-110 |
| `Alt + J` / `Ô` | Scroll down 15 lines | polish.lua:104-110 |
| `Alt + K` / `` | Scroll up 15 lines | polish.lua:105-110 |

## Plugin-Specific Keybindings

### Mini.move (Text Movement)
| Keybinding | Action | Location |
|------------|--------|----------|
| `Ctrl + Alt + h` | Move text/line left | user.lua:48-55 |
| `Ctrl + Alt + l` | Move text/line right | user.lua:49-55 |
| `Ctrl + Alt + j` | Move text/line down | user.lua:50-55 |
| `Ctrl + Alt + k` | Move text/line up | user.lua:51-55 |

### Mini.surround
| Keybinding | Action | Location |
|------------|--------|----------|
| `sa` | Add surrounding (normal/visual) | user.lua:30 |
| `sd` | Delete surrounding | user.lua:31 |
| `sf` | Find right surrounding | user.lua:32 |
| `sF` | Find left surrounding | user.lua:33 |
| `sh` | Highlight surrounding | user.lua:34 |
| `sr` | Replace surrounding | user.lua:35 |
| `sn` | Update n_lines | user.lua:36 |

### Mini.splitjoin
| Keybinding | Action | Location |
|------------|--------|----------|
| `gS` | Toggle split/join | user.lua:21 |

### GitHub Copilot
| Keybinding | Action | Location |
|------------|--------|----------|
| `Ctrl + g` | Accept suggestion (insert mode) | user.lua:221 |
| `Ctrl + j` | Next suggestion (insert mode) | user.lua:225 |
| `Ctrl + k` | Previous suggestion (insert mode) | user.lua:226 |
| `Ctrl + o` | Dismiss suggestion (insert mode) | user.lua:227 |

### Spectre (Search & Replace)
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>S` | Toggle Spectre | user.lua:252 |
| `<leader>sw` | Search current word (normal mode) | user.lua:253 |
| `<leader>sw` | Search current selection (visual mode) | user.lua:254 |
| `<leader>sp` | Search in current file | user.lua:255 |

### Debugging (DAP)
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>db` | Toggle breakpoint | polish.lua:153 |
| `<leader>dc` | Continue debugging | polish.lua:154 |
| `<leader>di` | Step into | polish.lua:155 |
| `<leader>do` | Step over | polish.lua:156 |
| `<leader>dO` | Step out | polish.lua:157 |
| `<leader>dr` | Toggle REPL | polish.lua:158 |
| `<leader>dl` | Run last | polish.lua:159 |
| `<leader>du` | Toggle DAP UI | polish.lua:160 |
| `<leader>dt` | Terminate debugging | polish.lua:161 |

### Testing (Neotest)
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>tt` | Run current test | polish.lua:166 |
| `<leader>tf` | Run all tests in file | polish.lua:167 |
| `<leader>td` | Debug current test | polish.lua:168 |
| `<leader>ts` | Stop test | polish.lua:169 |
| `<leader>ta` | Attach to test | polish.lua:170 |

### Dev Container
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>Ds` | Start dev container | user.lua:205 |
| `<leader>Da` | Attach to dev container | user.lua:206 |
| `<leader>Dt` | Stop dev container | user.lua:207 |
| `<leader>De` | Execute in container | user.lua:208 |
| `<leader>Dl` | View container logs | user.lua:209 |
| `<leader>Dr` | Remove all containers | user.lua:210 |
| `<leader>Dc` | Edit devcontainer config | user.lua:211 |

### Database Client (nvim-dbee)
| Keybinding | Action | Location |
|------------|--------|----------|
| `<leader>B` | Toggle database client | user.lua:229 |

## Custom Commands
| Command | Action | Location |
|---------|--------|----------|
| `:Q` | Force quit | polish.lua:53 |
| `:W` | Save with sudo | polish.lua:54 |
| `:X` | Save and exit with sudo | polish.lua:55 |

## AstroNvim Default Keybindings (Most Common)

### File Explorer & Navigation
| Keybinding | Action |
|------------|--------|
| `<leader>e` | Toggle Neo-tree file explorer |
| `<leader>o` | Toggle Neo-tree focus |

### Telescope (Fuzzy Finder)
| Keybinding | Action |
|------------|--------|
| `<leader>ff` | Find files |
| `<leader>fw` | Find word (grep) |
| `<leader>fW` | Find word under cursor |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Find help |
| `<leader>fm` | Find marks |
| `<leader>fo` | Find old files |
| `<leader>sb` | Git branches |
| `<leader>sc` | Git commits |
| `<leader>st` | Git status |

### LSP (Language Server)
| Keybinding | Action |
|------------|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `<leader>lh` | Hover documentation |
| `<leader>ls` | Symbol outline |
| `<leader>lr` | Rename symbol |
| `<leader>la` | Code action |
| `<leader>lf` | Format code |

### Terminal
| Keybinding | Action |
|------------|--------|
| `<leader>th` | Toggle horizontal terminal |
| `<leader>tv` | Toggle vertical terminal |
| `<leader>tf` | Toggle floating terminal |

### Session Management
| Keybinding | Action |
|------------|--------|
| `<leader>Sl` | Load session |
| `<leader>Ss` | Save session |
| `<leader>S.` | Load current directory session |

## Configuration Details

### Custom Settings
- **Clipboard**: Explicitly disabled system clipboard integration - must use `<leader>y/p` for system clipboard
- **Color scheme**: base16-darkmoss theme with transparent background
- **Indentation**: 2 spaces (expandtab, softtabstop=2, shiftwidth=2)
- **Line numbers**: Absolute line numbers (relativenumber=false)
- **Mouse**: Enabled
- **Search**: Incremental search enabled

### Plugin Customizations
- **Neo-tree**: Shows hidden files by default (`visible = true`)
- **Snacks picker**: Custom telescope icon (🔭)
- **Mini.snippets**: Available but no custom keybindings
- **DAP**: Auto-opens/closes UI, supports Python and JavaScript/TypeScript debugging
- **Neotest**: Supports Python (pytest), Jest, and Vitest
- **nvim-dbee**: Database client for PostgreSQL, MySQL, SQLite, and more

### Available Color Schemes
- base16-darkmoss (active)
- base16-nvim (other base16 themes available)
- material.nvim
- minimal.nvim

## Tips
- **Leader key**: `Space`
- **AstroNvim**: This config extends AstroNvim, so many standard AstroNvim keybindings are available
- **Fast scrolling**: Use Alt+j/k for 5-line jumps, Alt+J/K for 15-line jumps  
- **Fold management**: Use `\` to toggle folds or create them in visual mode
- **Mac keyboard**: Special character mappings (∆, ˚, Ô, ) for Alt combinations
- **Sudo operations**: Custom `:W` and `:X` commands for sudo save/exit