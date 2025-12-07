# 🔨 Hammerspoon Configuration - User Guide

> **A comprehensive guide to your Hammerspoon automation setup for macOS**

## 📋 Table of Contents

- [🔧 Quick Start](#-quick-start)
- [⌨️ Hotkeys](#️-hotkeys)
- [🎯 Features](#-features)
- [🔧 Configuration](#-configuration)
- [🎨 Customization](#-customization)
- [💡 Pro Tips](#-pro-tips)

---

## 🔧 Quick Start

### Installation
Hammerspoon is automatically installed via your dotfiles setup. If you need to install manually:

```bash
# Install Hammerspoon
brew install --cask hammerspoon

# Link configuration (done automatically by install.sh)
ln -sf ~/.dotfiles/config/hammerspoon ~/.config/hammerspoon
```

### First Launch
1. **Launch Hammerspoon** from Applications or Spotlight
2. **Grant Accessibility Permissions** when prompted
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Check the box next to Hammerspoon
3. **Reload Configuration** (⌘⇧R) or restart Hammerspoon

---

## ⌨️ Hotkeys

### 🚀 Kitty Terminal Focus
| Hotkey | Action |
|--------|--------|
| `Alt+Space` | Focus Kitty terminal (launch if not running) |
| `Alt+Space` (again) | Hide Kitty if already focused (toggle behavior) |

### 🔄 Configuration Management
| Hotkey | Action |
|--------|--------|
| `⌘⇧R` | Reload Hammerspoon configuration |
| `⌘⇧C` | Open Hammerspoon console |

---

## 🎯 Features

### 🖥️ Kitty Terminal Integration
- **Smart Focus**: Brings Kitty to focus or launches if not running
- **Toggle Behavior**: Hide Kitty if already focused
- **All Windows**: Brings all Kitty windows to front
- **Instant Response**: No delay in activation

### 🔄 Auto-Reload
- **File Watching**: Automatically reloads when configuration changes
- **Instant Updates**: No need to manually reload after edits
- **Notifications**: Shows confirmation when configuration reloads

### 📢 Notifications
- **Startup**: Confirms hotkey is loaded
- **Reload**: Notifies when configuration updates
- **Non-intrusive**: Brief, informative messages

---

## 🔧 Configuration

### 📁 File Location
- **Config Directory**: `~/.hammerspoon/`
- **Source**: `~/.dotfiles/config/hammerspoon/`
- **Symlinked**: `~/.hammerspoon/` → `~/.dotfiles/config/hammerspoon/`

### 🎛️ Core Configuration
```lua
-- Focus or launch Kitty
function focusKitty()
    local kitty = hs.application.find("kitty")
    
    if kitty then
        if kitty:isFrontmost() then
            kitty:hide()        -- Hide if already focused
        else
            kitty:activate()    -- Focus if running
        end
    else
        hs.application.launchOrFocus("kitty")  -- Launch if not running
    end
end

-- Bind Alt+Space
hs.hotkey.bind({"alt"}, "space", focusKitty)
```

### 🔧 Auto-Reload Setup
```lua
-- Watch for file changes
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", reloadConfig):start()
```

---

## 🎨 Customization

### 🔧 Adding New Hotkeys
Edit `~/.config/hammerspoon/init.lua` to add custom hotkeys:

```lua
-- Example: Alt+T for new Kitty window
hs.hotkey.bind({"alt"}, "t", function()
    hs.application.launchOrFocus("kitty")
    hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({"cmd"}, "n")  -- Cmd+N for new window
    end)
end)

-- Example: Alt+Shift+Space for new Kitty tab
hs.hotkey.bind({"alt", "shift"}, "space", function()
    local kitty = hs.application.find("kitty")
    if kitty then
        kitty:activate()
        hs.timer.doAfter(0.1, function()
            hs.eventtap.keyStroke({"cmd"}, "t")  -- Cmd+T for new tab
        end)
    else
        hs.application.launchOrFocus("kitty")
    end
end)
```

### 🎯 Other Applications
Add hotkeys for other applications:

```lua
-- Focus other applications
hs.hotkey.bind({"alt"}, "c", function()
    hs.application.launchOrFocus("Google Chrome")
end)

hs.hotkey.bind({"alt"}, "v", function()
    hs.application.launchOrFocus("Code")
end)

hs.hotkey.bind({"alt"}, "s", function()
    hs.application.launchOrFocus("Slack")
end)
```

### 🪟 Window Management
Add window management features:

```lua
-- Move window to left half
hs.hotkey.bind({"alt", "cmd"}, "left", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    
    f.x = max.x
    f.y = max.y
    f.w = max.w / 2
    f.h = max.h
    win:setFrame(f)
end)

-- Move window to right half
hs.hotkey.bind({"alt", "cmd"}, "right", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    
    f.x = max.x + (max.w / 2)
    f.y = max.y
    f.w = max.w / 2
    f.h = max.h
    win:setFrame(f)
end)
```

---

## 💡 Pro Tips

### 🚀 Productivity Tips

#### iTerm2 Migration
If you're coming from iTerm2, this setup provides the same Alt+Space behavior:
- **Same hotkey**: Alt+Space works identically
- **Same behavior**: Focus, launch, or hide terminal
- **Better performance**: Hammerspoon is lighter than iTerm2's hotkey system

#### Multiple Terminal Workflows
```lua
-- Different terminals for different purposes
hs.hotkey.bind({"alt"}, "space", focusKitty)           -- Development
hs.hotkey.bind({"alt", "shift"}, "space", function()   -- Admin tasks
    hs.application.launchOrFocus("Terminal")
end)
```

#### Quick App Switching
Create a unified app launcher:
```lua
local appHotkeys = {
    k = "kitty",
    c = "Google Chrome",
    s = "Slack",
    v = "Code",
    f = "Finder"
}

for key, app in pairs(appHotkeys) do
    hs.hotkey.bind({"alt"}, key, function()
        hs.application.launchOrFocus(app)
    end)
end
```

### 🔧 Advanced Configuration

#### Conditional Behavior
```lua
-- Different behavior based on time of day
function smartFocusKitty()
    local hour = tonumber(os.date("%H"))
    local kitty = hs.application.find("kitty")
    
    if hour >= 9 and hour <= 17 then
        -- Work hours: focus existing or launch
        if kitty then
            kitty:activate()
        else
            hs.application.launchOrFocus("kitty")
        end
    else
        -- After hours: only focus if running
        if kitty then
            kitty:activate()
        end
    end
end
```

#### Multi-Monitor Support
```lua
-- Move Kitty to specific screen
hs.hotkey.bind({"alt", "cmd"}, "space", function()
    local kitty = hs.application.find("kitty")
    if kitty then
        local screens = hs.screen.allScreens()
        if #screens > 1 then
            local targetScreen = screens[2]  -- Second monitor
            kitty:mainWindow():moveToScreen(targetScreen)
        end
        kitty:activate()
    end
end)
```

### 🎯 Debugging

#### Hammerspoon Console
- **Open**: ⌘⇧C or click Hammerspoon menu bar icon
- **Logs**: View real-time lua execution
- **Testing**: Run lua commands interactively

#### Testing Hotkeys
```lua
-- Add debug notifications
hs.hotkey.bind({"alt"}, "space", function()
    hs.notify.new({title="Debug", informativeText="Alt+Space pressed"}):send()
    focusKitty()
end)
```

---

## 🔍 Troubleshooting

### Common Issues

#### Hotkey Not Working
1. **Check Accessibility**: System Preferences → Security & Privacy → Privacy → Accessibility
2. **Reload Config**: ⌘⇧R in Hammerspoon
3. **Check Console**: ⌘⇧C for error messages

#### Hammerspoon Not Starting
```bash
# Check if Hammerspoon is installed
ls /Applications/Hammerspoon.app

# Launch manually
open /Applications/Hammerspoon.app

# Check configuration
ls -la ~/.config/hammerspoon/init.lua
```

#### Configuration Errors
```bash
# Check lua syntax
lua -c ~/.config/hammerspoon/init.lua

# View Hammerspoon logs
tail -f ~/.config/hammerspoon/console.log
```

---

## 📚 Resources

### 🔗 Documentation
- **[Hammerspoon API](http://www.hammerspoon.org/docs/)** - Complete API reference
- **[Getting Started](http://www.hammerspoon.org/go/)** - Official tutorial
- **[Sample Configs](https://github.com/Hammerspoon/hammerspoon/wiki/Sample-Configurations)** - Community examples

### 🎯 Key Modules
- **`hs.application`** - Application control
- **`hs.hotkey`** - Hotkey binding
- **`hs.window`** - Window management
- **`hs.pathwatcher`** - File watching
- **`hs.notify`** - Notifications

---

> **💡 Pro Tip**: Use the Hammerspoon console (⌘⇧C) to test lua commands interactively and debug your configuration. The auto-reload feature means you can edit your config file and see changes immediately!

**Happy automating!** 🚀