# 🐱 Kitty Terminal Configuration

Customized Kitty setup — font, appearance, and keybindings.

## Quick Start

```bash
brew install kitty
ln -sf ~/.dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

Reload after edits with `Ctrl+Shift+F5` (`Ctrl+Shift+F6` to debug config).

## Configuration

**Font:** `CaskaydiaCove Nerd Font Mono`, size 13, auto bold/italic, default line/column spacing.

**Window:** 10px padding, decorations hidden, remembers size, audio bell on, powerline tabs at top (active tab bold).

**Scrollback:** 50,000 lines, paged with `less`, wheel multiplier 5.0.

**Mouse:** auto-hide after 3s, URLs in cyan (Ctrl+Click opens), copy-on-select, system default browser.

**Performance:** input delay 1ms, repaint 10ms, sync-to-monitor on (GPU acceleration is on by default).

## Keyboard Shortcuts

### Windows
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+Enter` | New window |
| `Ctrl+Shift+W` | Close window |
| `Ctrl+Shift+]` / `[` | Next / previous window |
| `Ctrl+Shift+F` / `B` | Move window forward / backward |
| `Ctrl+Shift+R` | Resize window |
| `Ctrl+Shift+L` | Next layout |

### Tabs
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+Q` | Close tab |
| `Ctrl+Shift+Right` / `Left` | Next / previous tab |
| `Ctrl+Shift+Alt+T` | Set tab title |

### Text & selection
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+C` / `V` | Copy / paste clipboard |
| `Ctrl+Shift+S` | Paste from selection |
| `Ctrl+Shift+Up` / `Down` | Scroll line |
| `Ctrl+Shift+Page Up` / `Down` | Scroll page |
| `Ctrl+Shift+Home` / `End` | Scroll to top / bottom |

### Config & display
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+F5` / `F6` | Reload / debug config |
| `Ctrl+Shift+Delete` | Clear terminal |
| `Ctrl+Shift+F11` / `F10` | Toggle fullscreen / maximized |

Mouse: double/triple-click selects word/line, Ctrl+Click opens URLs, middle-click pastes selection.

## Layouts

Available layouts: tall, fat, grid, horizontal, vertical (cycle with `Ctrl+Shift+L`).

## Troubleshooting

- **Font not found:** `kitty +list-fonts`; install with `brew install --cask font-jetbrains-mono-nerd-font`.
- **SSH/terminfo issues:** use `kitty +kitten ssh user@host`, or `export TERM=xterm-256color`.
- **Debug rendering:** `kitty --debug-gl`; reduce `scrollback_lines` if memory is tight.
