-- Zoom and bar hiding for the multiplexers nvim runs inside: tmux, herdr or the
-- Herdr app. Acts on every multiplexer present. Nvim in tmux in herdr zooms
-- both.
local M = {}

-- A multiplexer may be gone or hung. A failure reads as "not zoomed".
local function run(cmd)
    local ok, proc = pcall(vim.system, cmd, { text = true })
    if not ok then
        return ""
    end
    local result = proc:wait(1000)
    return result.code == 0 and (result.stdout or "") or ""
end

local function tmux_is_zoomed()
    return run({ "tmux", "list-panes", "-F", "#{?pane_active,#{window_zoomed_flag},}" }):match("1") ~= nil
end

local function tmux_set_zoom(on)
    -- resize-pane -Z only toggles
    if tmux_is_zoomed() ~= on then
        run({ "tmux", "resize-pane", "-Z" })
    end
end

-- herdr's --current follows the focused pane. --pane with nvim's own pane id targets nvim's pane.
local function herdr_pane() return require("lib.herdr").pane_id() end

local function herdr_is_zoomed()
    local bin = require("lib.herdr").bin()
    return run({ bin, "pane", "layout", "--pane", herdr_pane() }):match('"zoomed"%s*:%s*true') ~= nil
end

local function herdr_set_zoom(on)
    local bin = require("lib.herdr").bin()
    run({ bin, "pane", "zoom", "--pane", herdr_pane(), on and "--on" or "--off" })
end

-- An adapter's enter returns what its leave needs to put the multiplexer back.
local adapters = {
    tmux = {
        present = function() return vim.env.TMUX ~= nil end,
        enter = function()
            local was = { zoomed = tmux_is_zoomed() }
            run({ "tmux", "set", "status", "off" })
            tmux_set_zoom(true)
            return was
        end,
        leave = function(was)
            run({ "tmux", "set", "status", "on" })
            tmux_set_zoom(was.zoomed)
        end,
    },
    -- The tab bar is config-time only. The sidebar toggles by keystroke.
    herdr = {
        present = function() return herdr_pane() ~= nil end,
        enter = function()
            local herdr = require("lib.herdr")
            local was = { zoomed = herdr_is_zoomed(), sidebar = not herdr.sidebar_collapsed() }
            herdr_set_zoom(true)
            if was.sidebar then
                herdr.toggle_sidebar()
            end
            return was
        end,
        leave = function(was)
            local herdr = require("lib.herdr")
            herdr_set_zoom(was.zoomed)
            -- The user may have toggled the sidebar during zen
            if was.sidebar and herdr.sidebar_collapsed() then
                herdr.toggle_sidebar()
            end
        end,
    },
    -- herdr-app's CLI reports no zoom state. The app's keys mod
    -- (herdr/app/mods/keys) saves the zoom state at keys.zen-in, restores it at
    -- keys.zen-out, and hides and shows the bars with it.
    herdr_app = {
        present = function() return require("lib.herdr_app").inside() end,
        enter = function()
            require("lib.herdr_app").run("keys.zen-in")
            return {}
        end,
        leave = function() require("lib.herdr_app").run("keys.zen-out") end,
    },
}

local function present()
    local found = {}
    for name, adapter in pairs(adapters) do
        if adapter.present() then
            found[name] = adapter
        end
    end
    return found
end

---@return table<string, table> what each multiplexer's leave restores
function M.zoom_in()
    local was = {}
    for name, adapter in pairs(present()) do
        was[name] = adapter.enter()
    end
    return was
end

---@param was table<string, table> from `zoom_in`
function M.restore(was)
    for name, adapter in pairs(present()) do
        if was[name] then
            adapter.leave(was[name])
        end
    end
end

return M
