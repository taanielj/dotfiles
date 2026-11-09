-- Window focus (cmd+hjkl) and resize (alt+hjkl, alt+shift+hjkl for one
-- percent) by direction: the macOS layer under nvim windows and herdr panes.
-- The terminals turn cmd+hjkl into herdr's ctrl+hjkl, and the Herdr app binds
-- cmd+hjkl itself, so the keys stand down while a window running herdr or the
-- app is in front; herdr, the app and nvim reach these functions through
-- `hs -c` once they run out of panes.

require("hs.ipc") -- serves the hs command the cask links into /opt/homebrew/bin
hs.autoLaunch(true)
hs.accessibilityState(true) -- asks for Accessibility access until it is granted
hs.window.animationDuration = 0

-- Reload on save; a file that fails to parse keeps the running config and shows
-- why. Set up before anything that could error, so a broken save can't stop it.
-- Watches the symlink's target directory: saves there never touch hs.configdir.
local configFile = hs.fs.pathToAbsolute(hs.configdir .. "/init.lua")
configWatcher = hs.pathwatcher -- global, or garbage collection stops it
    .new(configFile:match("^(.*)/"), function()
        local _, err = loadfile(configFile)
        if err then hs.showError(err) else hs.reload() end
    end)
    :start()

local TERMINALS = { "Ghostty", "kitty" }
local HERDR_TITLE = "herdr · " -- how herdr's ui.window_title (herdr/config.toml) starts
local HERDR_APP = "dev.herdr.app" -- the Herdr desktop app's bundle id (herdr-app/)
local STEP = 0.05 -- of the screen, per resize press
local FINE_STEP = 0.01
local TOUCH = 10 -- px; windows this close share a border

---@param win? hs.window
---@return boolean herdr or the Herdr app runs the window, so it gets the keys first
local function runsHerdr(win)
    local app = win and win:application()
    if app == nil then return false end
    if app:bundleID() == HERDR_APP then return true end
    return hs.fnutils.contains(TERMINALS, app:name()) and win:title():sub(1, #HERDR_TITLE) == HERDR_TITLE
end

local WINDOWS_TO = {
    left = "windowsToWest",
    right = "windowsToEast",
    up = "windowsToNorth",
    down = "windowsToSouth",
}

---Focus the nearest unoccluded window in a direction.
---@param dir "left"|"down"|"up"|"right"
---@return boolean focused false when there is no window that way
function focusWindow(dir)
    local win = hs.window.focusedWindow()
    local target = win and win[WINDOWS_TO[dir]](win, nil, true, true)[1]
    if not target then return false end
    target:focus()
    -- Activating an app raises its last key window over the target, as with
    -- two Zen windows; once the app is in front, focusing again sticks.
    hs.timer.doAfter(0, function() target:focus() end)
    return true
end

local function overlaps(a, b, pos, size) return a[pos] < b[pos] + b[size] and b[pos] < a[pos] + a[size] end

---Move a border of the focused window in a direction, like smart-splits: the
---right or bottom border, or the left or top one when the window sits against
---that side of the screen. A window flush against the moved border follows it.
---@param dir "left"|"down"|"up"|"right"
---@param step? number fraction of the screen, STEP by default
---@return boolean resized false when no window has focus or the border is at the screen's side
function resizeWindow(dir, step)
    local win = hs.window.focusedWindow()
    if not win then return false end
    local horizontal = dir == "left" or dir == "right"
    local pos, size, cross, crossSize = "x", "w", "y", "h"
    if not horizontal then pos, size, cross, crossSize = "y", "h", "x", "w" end

    local f, s = win:frame(), win:screen():frame()
    local far = f[pos] + f[size] < s[pos] + s[size] - TOUCH
    local border = far and f[pos] + f[size] or f[pos]
    local delta = s[size] * (step or STEP) * ((dir == "left" or dir == "up") and -1 or 1)
    delta = math.max(s[pos], math.min(s[pos] + s[size], border + delta)) - border
    if delta == 0 then return false end

    for _, other in ipairs(hs.window.visibleWindows()) do
        local o = other:frame()
        if other ~= win and other:isStandard() and overlaps(f, o, cross, crossSize) then
            if far and math.abs(o[pos] - border) <= TOUCH then
                o[pos], o[size] = o[pos] + delta, o[size] - delta
                other:setFrame(o)
            elseif not far and math.abs(o[pos] + o[size] - border) <= TOUCH then
                o[size] = o[size] + delta
                other:setFrame(o)
            end
        end
    end

    if far then
        f[size] = f[size] + delta
    else
        f[pos], f[size] = f[pos] + delta, f[size] - delta
    end
    win:setFrame(f)
    return true
end

local DIRS = { h = "left", j = "down", k = "up", l = "right" }
-- With no window that way, cmd+j and cmd+k reach the app (Slack's cmd+k);
-- cmd+h would hide the app, so h and l always stay focus keys.
local PASS_THROUGH = { j = true, k = true }

local focusKeyCodes = {}
for key in pairs(DIRS) do focusKeyCodes[hs.keycodes.map[key]] = key end

-- global, or garbage collection stops it
focusTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local key = focusKeyCodes[event:getKeyCode()]
    if not key or not event:getFlags():containExactly({ "cmd" }) then return false end
    return focusWindow(DIRS[key]) or not PASS_THROUGH[key]
end)

local hotkeys = {}
for key, dir in pairs(DIRS) do
    local resize = function() resizeWindow(dir) end
    table.insert(hotkeys, hs.hotkey.new({ "alt" }, key, resize, nil, resize))
    local fine = function() resizeWindow(dir, FINE_STEP) end
    table.insert(hotkeys, hs.hotkey.new({ "alt", "shift" }, key, fine, nil, fine))
end

local function follow()
    local on = not runsHerdr(hs.window.focusedWindow())
    for _, hotkey in ipairs(hotkeys) do
        if on then hotkey:enable() else hotkey:disable() end
    end
    if on then focusTap:start() else focusTap:stop() end
end

-- globals, or garbage collection stops them
frontAppWatcher = hs.application.watcher
    .new(function(_, event)
        if event == hs.application.watcher.activated then follow() end
    end)
    :start()
terminalWindows = hs.window.filter
    .new(TERMINALS)
    :subscribe({ hs.window.filter.windowFocused, hs.window.filter.windowTitleChanged }, follow)
follow()
