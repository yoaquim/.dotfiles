# 🚀 AstroNvim Configuration

Customized [AstroNvim](https://astronvim.com/) **v6** setup (requires Neovim ≥ 0.11; tested on 0.12). `<leader>` is `Space`. Theme: `base16-helios`.

## Quick Start

```bash
cd ~/.dotfiles && bash ./setup-astronvim.sh   # needs SSH keys (see main README)
```

Manual: clone the AstroNvim template into `~/.config/nvim`, then symlink `polish.lua` → `lua/polish.lua` and `user.lua` → `lua/plugins/user.lua`. Plugins auto-install on first `nvim`; `:Mason` verifies LSPs.

`polish.lua` holds settings/keymaps/commands; `user.lua` holds plugin specs (LSP, DAP, testing). Everything else under `~/.config/nvim` is the stock AstroNvim template (the `lua/plugins/*.lua` examples are inactive guard-returned files).

## Updating

- **Plugins:** `:Lazy update` — run it **twice**. AstroNvim pins plugin versions in its `lazy_snapshot`; the first pass updates AstroNvim itself (and the snapshot), the second applies the new pins.
- **AstroNvim major:** bump `version = "^N"` in `~/.config/nvim/lua/lazy_setup.lua` (not tracked in dotfiles — it comes from the template clone), then `:Lazy update` twice and check the [AstroNvim changelog](https://github.com/AstroNvim/AstroNvim/blob/main/CHANGELOG.md) for breaking changes. Last bump: v5 → v6 (2026-08-22).
- **Mason tools:** `:MasonToolsUpdate` (or `<leader>pM`).

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

Mason auto-installs LSPs for TS/JS, HTML/CSS/Tailwind, Python, Ruby, Bash, Docker, Terraform, YAML, Markdown, JSON — via `mason-tool-installer` `ensure_installed` in `user.lua` (AstroNvim ignores `mason-lspconfig.ensure_installed`; use Mason package names as shown in `:Mason`). AstroLSP auto-enables whatever Mason installs. Treesitter parsers (`ensure_installed`, highlight, indent) are configured through `AstroNvim/astrocore` `opts.treesitter` — nvim-treesitter `main` is only the parser installer. Categories: mini (surround/move/splitjoin/snippets, `nvim-mini/*`), nvim-dap (+ dap-ui, dap-python), neotest (python/jest/vitest), nvim-dev-container, nvim-dbee, spectre, themes (base16/material/minimal).

## Troubleshooting

- **Clipboard:** use `<leader>y` / `<leader>p` (system clipboard is intentionally off).
- **LSP not starting:** `:Mason` to verify, `:LspRestart`, `:checkhealth`. If a server is missing, `:MasonToolsInstall`.
- **Red Lua traceback when opening a file** (e.g. aerial `attempt to call method 'start'`): a pinned plugin fell behind Neovim. Check `:Lazy` for the plugin's version pin and the AstroNvim `version` in `lazy_setup.lua` — a new AstroNvim major usually carries the fix (see Updating).
- **Keymaps "not working"** (e.g. `sa` surround): often a side-effect of the above — the `Press ENTER` error prompt eats keystrokes. Fix the error first.
- **Debugging:** Python needs `debugpy`; JS needs Node. `:checkhealth` for diagnostics.
- Press `<leader>` for the which-key menu of all bindings.
