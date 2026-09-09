-- Zoom and chrome of the multiplexers nvim runs inside. Every one that is
-- present is driven, so nvim in tmux in herdr zooms both.
local M = {}

-- A multiplexer may be gone or hung, so a failure reads as "not zoomed"
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

-- herdr's --current follows the focused pane, so this pane is addressed by id
local function herdr_pane()
    return vim.env.HERDR_PANE_ID
end

local adapters = {
    tmux = {
        present = function()
            return vim.env.TMUX ~= nil
        end,
        is_zoomed = tmux_is_zoomed,
        set_zoom = function(on)
            -- resize-pane -Z only toggles
            if tmux_is_zoomed() ~= on then
                run({ "tmux", "resize-pane", "-Z" })
            end
        end,
        set_chrome = function(visible)
            run({ "tmux", "set", "status", visible and "on" or "off" })
        end,
    },
    herdr = {
        present = function()
            return require("lib.herdr").inside() and vim.env.HERDR_PANE_ID ~= nil
        end,
        is_zoomed = function()
            return run({ "herdr", "pane", "layout", "--pane", herdr_pane() }):match('"zoomed"%s*:%s*true') ~= nil
        end,
        set_zoom = function(on)
            run({ "herdr", "pane", "zoom", "--pane", herdr_pane(), on and "--on" or "--off" })
        end,
        -- The sidebar and tab bar are config-time only
        set_chrome = function() end,
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

---Hides the chrome and zooms in; returns what `restore` needs.
---@return table<string, boolean> zoomed before, by multiplexer
function M.zoom_in()
    local was = {}
    for name, adapter in pairs(present()) do
        was[name] = adapter.is_zoomed()
        adapter.set_chrome(false)
        adapter.set_zoom(true)
    end
    return was
end

---@param was table<string, boolean> from `zoom_in`
function M.restore(was)
    for name, adapter in pairs(present()) do
        adapter.set_chrome(true)
        adapter.set_zoom(was[name] == true)
    end
end

return M
