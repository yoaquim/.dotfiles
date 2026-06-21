# 🖥️ Tmux Configuration

Customized tmux setup. **Prefix is backtick `` ` `` (not `Ctrl+b`)** — press `` ` ` `` for a literal backtick.

## Quick Start

```bash
brew install tmux
ln -sf ~/.dotfiles/config/tmux/tmux.conf ~/.config/tmux/tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
tmux        # then press ` + I (capital i) to install plugins
```

## Key Bindings

All bindings are `` ` `` (prefix) followed by:

### Windows
| Key | Action |
|-----|--------|
| `,` / `.` | Previous / next window |
| `H` / `L` (or `u` / `i`) | Previous / next (alternatives) |
| `n` / `N` | Rename window / session |
| `m` | Move window to index |
| `x` / `X` | Kill pane / window |

### Panes
| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Select left / down / up / right (vim-style) |
| `\` / `-` | Split horizontal / vertical |
| `Left` `Right` `Up` `Down` | Resize by 5 cells |
| `v` / `b` / `t` | Even-horizontal / even-vertical / tiled layout |
| `o` | Rotate panes |

### System
| Key | Action |
|-----|--------|
| `Space` | Command prompt |
| `r` | Reload config |

## Behavior

- Windows base-index 1, auto-rename, aggressive-resize, titles in terminal bar.
- Mouse on (click/drag/scroll), vi copy-mode, 50,000-line scrollback.
- `screen-256color`, status updates every 5s, no activity/visual-bell noise.

## Plugins

| Plugin | Purpose / keys |
|--------|----------------|
| **TPM** | Plugin manager — `` ` I `` install, `` ` U `` update, `` ` alt+u `` uninstall |
| **Resurrect** | Save/restore sessions — `` ` Ctrl+s `` / `` ` Ctrl+r `` (preserves panes, windows, cwd) |
| **Continuum** | Auto-save every 15 min, auto-restore on start |
| **Yank** | Clipboard — `y` copy selection, `Y` copy line |
| **Powerline** | Status line (theme from `config/tmux-powerline/`) |
| **Fingers** | `` ` F `` highlights URLs/paths/files; press the letter to copy |
| **Mighty Scroll / Better Mouse Mode** | Smoother mouse-wheel scrolling |

## Troubleshooting

- **Plugins not installing:** confirm TPM is cloned (path above), then `` ` I `` inside tmux.
- **Colors off:** `echo $TERM` should be `screen-256color` inside tmux.
- **Reload after edits:** `` ` r `` or `tmux source-file ~/.config/tmux/tmux.conf`.
