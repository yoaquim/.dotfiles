# 🔨 Hammerspoon Configuration

macOS automation. This config does one thing: **`Alt+Space` focuses Kitty** (launches it if not running, hides it if already frontmost), with auto-reload on config change.

## Setup

```bash
brew install --cask hammerspoon
ln -sf ~/.dotfiles/config/hammerspoon ~/.config/hammerspoon   # done by install.sh
```

On first launch, grant **Accessibility** permission (System Settings → Privacy & Security → Accessibility), then reload with `⌘⇧R`.

## Hotkeys

| Hotkey | Action |
|--------|--------|
| `Alt+Space` | Focus Kitty (launch if needed; hide if already focused) |
| `⌘⇧R` | Reload config |
| `⌘⇧C` | Open console |

Config lives in `~/.hammerspoon/init.lua` (symlinked from `config/hammerspoon/`). A `hs.pathwatcher` reloads it automatically on save.

## Extending

Bind more hotkeys in `init.lua`, e.g. launch/focus another app:

```lua
hs.hotkey.bind({"alt"}, "c", function()
    hs.application.launchOrFocus("Google Chrome")
end)
```

See the [Hammerspoon API docs](http://www.hammerspoon.org/docs/) — useful modules: `hs.application`, `hs.hotkey`, `hs.window`, `hs.pathwatcher`, `hs.notify`.

## Troubleshooting

- **Hotkey dead:** confirm Accessibility is granted, then `⌘⇧R`; check the console (`⌘⇧C`) for errors.
- **Won't start:** `open /Applications/Hammerspoon.app`; verify `~/.config/hammerspoon/init.lua` exists.
- **Config error:** `lua -c ~/.config/hammerspoon/init.lua` to check syntax.
