-- Window navigation and resize through whichever splits plugin owns the keys:
-- herdr-splits inside herdr, smart-splits elsewhere. At nvim's edge inside the
-- Herdr app, the app's keys mod takes over. herdr-splits resizes by a
-- ratio of the pane and smart-splits by cells, so a fine step differs too.
local M = {}

local function plugin() return require(require("lib.herdr").inside() and "herdr-splits" or "smart-splits") end

local WINCMD = { left = "h", down = "j", up = "k", right = "l" }
local AXIS = { left = { "left", "right" }, right = { "left", "right" }, up = { "up", "down" }, down = { "up", "down" } }

---@param sides ("left"|"down"|"up"|"right")[]
---@return boolean every side is nvim's edge
local function at_nvim_edge(sides)
    for _, side in ipairs(sides) do
        if vim.fn.winnr(WINCMD[side]) ~= vim.fn.winnr() then
            return false
        end
    end
    return true
end

---@param sides ("left"|"down"|"up"|"right")[]
---@return boolean outer every side is both nvim's edge and its unzoomed herdr pane's
---layout edge, so the next layer out is the macOS window (hammerspoon/init.lua)
local function at_outer_edge(sides)
    local herdr = require("lib.herdr")
    if not herdr.inside() or vim.fn.executable("hs") == 0 or not at_nvim_edge(sides) then
        return false
    end
    local res = vim.system({ herdr.bin(), "pane", "edges", "--current" }, { text = true }):wait()
    local ok, data = pcall(vim.json.decode, res.stdout or "")
    local edges = ok and data.result and data.result.edges
    if not edges or edges.layout.zoomed then
        return false
    end
    for _, side in ipairs(sides) do
        if not edges[side] then
            return false
        end
    end
    return true
end

---@param code string Lua for Hammerspoon to run
---@return boolean ran and returned true; false while Hammerspoon is down, which
---relaunches it, since `hs` would hang instead
local function hammerspoon(code)
    if vim.system({ "pgrep", "-xq", "Hammerspoon" }):wait().code ~= 0 then
        vim.system({ "open", "-g", "-a", "Hammerspoon" })
        return false
    end
    local res = vim.system({ "hs", "-c", code }, { text = true }):wait()
    return vim.trim(res.stdout or "") == "true"
end

---@param dir "left"|"down"|"up"|"right"
function M.move(dir)
    -- The app's keys mod carries on into panes and macOS windows (herdr-app/mods/keys)
    local app = require("lib.herdr_app")
    if app.inside() and at_nvim_edge({ dir }) then
        app.run("keys.go-" .. dir)
        return
    end
    if at_outer_edge({ dir }) and hammerspoon(("focusWindow('%s')"):format(dir)) then
        return
    end
    plugin()["move_cursor_" .. dir]()
end

---@param dir "left"|"down"|"up"|"right"
---@param fine? boolean one cell, or one percent of a herdr pane or the screen
function M.resize(dir, fine)
    local app = require("lib.herdr_app")
    if app.inside() and at_nvim_edge(AXIS[dir]) then
        app.run("keys.resize-outside-" .. dir .. (fine and "-fine" or ""))
        return
    end
    if at_outer_edge(AXIS[dir]) and hammerspoon(("resizeWindow('%s', %s)"):format(dir, fine and 0.01 or "nil")) then
        return
    end
    local amount = nil
    if fine then
        amount = require("lib.herdr").inside() and 0.01 or 1
    end
    plugin()["resize_" .. dir](amount)
end

return M
