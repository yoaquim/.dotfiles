-- ───────────────────────────────────────────────────
-- Hammerspoon Configuration
-- ───────────────────────────────────────────────────

-- Kitty Focus Hotkey
-- ───────────────────────────────────────────────────

-- helper function to focus or launch kitty
function focusKitty()
    local kitty = hs.application.find("kitty")
    
    if kitty then
        -- if kitty is running, focus it
        if kitty:isFrontmost() then
            -- if kitty is already focused, hide it
            kitty:hide()
        else
            -- focus kitty and bring all windows to front
            kitty:activate()
        end
    else
        -- if kitty is not running, launch it
        hs.application.launchorfocus("kitty")
    end
end

-- bind alt+space to focus kitty
hs.hotkey.bind({"alt"}, "space", focusKitty)

-- Configuration Management
-- ───────────────────────────────────────────────────

-- auto-reload configuration when file changes
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
        hs.notify.new({
            title="Hammerspoon", 
            informativeText="Configuration reloaded"
        }):send()
    end
end

-- watch for config file changes
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", reloadConfig):start()

-- Startup Notification
-- ───────────────────────────────────────────────────

-- show notification when hammerspoon loads
hs.notify.new({
    title="Hammerspoon", 
    informativeText="Kitty hotkey loaded (Alt+Space)"
}):send()

-- Optional: Additional Hotkeys
-- ───────────────────────────────────────────────────

-- Uncomment these if you want additional functionality:

-- Alt+T for new Kitty window
-- hs.hotkey.bind({"alt"}, "t", function()
--     hs.application.launchOrFocus("kitty")
--     hs.timer.doAfter(0.1, function()
--         hs.eventtap.keyStroke({"cmd"}, "n")
--     end)
-- end)

-- Alt+Shift+Space for Kitty new tab
-- hs.hotkey.bind({"alt", "shift"}, "space", function()
--     local kitty = hs.application.find("kitty")
--     if kitty then
--         kitty:activate()
--         hs.timer.doAfter(0.1, function()
--             hs.eventtap.keyStroke({"cmd"}, "t")
--         end)
--     else
--         hs.application.launchOrFocus("kitty")
--     end
-- end)
