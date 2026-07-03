# 🚀 AstroNvim Configuration

Customized AstroNvim setup. `<leader>` is `Space`. Theme: `base16-darkmoss`.

## Quick Start

```bash
cd ~/.dotfiles && bash ./setup-astronvim.sh   # needs SSH keys (see main README)
```

Manual: clone the AstroNvim template into `~/.config/nvim`, then symlink `polish.lua` → `lua/polish.lua` and `user.lua` → `lua/plugins/user.lua`. Plugins auto-install on first `nvim`; `:Mason` verifies LSPs.

`polish.lua` holds settings/keymaps/commands; `user.lua` holds plugin specs (LSP, DAP, testing).

## Keymaps

### Files
| Key | Action |
|-----|--------|
| `<leader>w` / `W` | Save / save with sudo |
| `<leader>q` / `Q` | Quit / force quit |
| `<leader>x` / `X` | Save & quit / with sudo |

### Clipboard (system clipboard is opt-in)
| Key | Action |
|-----|--------|
| `<leader>y` / `yy` / `Y` | Copy selection / line / to end of line |
| `<leader>p` / `P` | Paste after / before |
| `<leader>pp` / `PP` | Paste after / before with auto-indent |

### Buffers & windows
| Key | Action |
|-----|--------|
| `<leader>j` / `k` | Previous / next buffer |
| `<leader>bd` / `bl` | Delete buffer / list buffers |
| `<C-h/j/k/l>` | Move to left/down/up/right window |

### Scroll, search, delete
| Key | Action |
|-----|--------|
| `<M-j>` / `<M-k>` | Scroll 5 lines down / up |
| `<M-J>` / `<M-K>` | Scroll 15 lines down / up |
| `<leader>h` | Toggle search highlight |
| `\` | Toggle fold (Visual: create fold) |
| `<leader>d` / `x` | Delete without yanking |

### mini.nvim
| Key | Action |
|-----|--------|
| `sa` / `sd` / `sr` / `sf` / `sF` | Surround add / delete / replace / find right / find left |
| `gS` | Split/join lines |
| `<C-M-h/j/k/l>` | Move text/selection |

### Debugging (nvim-dap)
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` / `di` / `do` / `dO` | Continue / step into / over / out |
| `<leader>dr` / `dl` | Toggle REPL / run last |
| `<leader>du` / `dt` | Toggle UI / terminate |

### Testing (neotest)
| Key | Action |
|-----|--------|
| `<leader>tt` / `tf` | Run test under cursor / file |
| `<leader>td` / `ts` / `ta` | Debug / stop / attach |

### Other
| Key / Cmd | Action |
|-----------|--------|
| `<leader>B` | Toggle database client (nvim-dbee) |
| `:Q` / `:W` / `:X` | Force quit / sudo save / sudo save-quit |

**Settings:** system clipboard off by default (use `<leader>y/p`), absolute line numbers, 2-space expanded tabs, mouse on, incremental search.

## Plugins

Mason auto-installs LSPs for TS/JS, HTML/CSS/Tailwind, Python, Ruby, Bash, Docker, Terraform, YAML, Markdown, JSON. Categories: mini (surround/move/splitjoin), Treesitter, nvim-dap (+ dap-ui, dap-python), neotest (python/jest), nvim-dev-container, nvim-dbee, themes (base16/material/minimal).

## Troubleshooting

- **Clipboard:** use `<leader>y` / `<leader>p` (system clipboard is intentionally off).
- **LSP not starting:** `:Mason` to verify, `:LspRestart`, `:checkhealth`.
- **Debugging:** Python needs `debugpy`; JS needs Node. `:checkhealth` for diagnostics.
- Press `<leader>` for the which-key menu of all bindings.
