-- Window navigation and resize through whichever splits plugin owns the keys:
-- herdr-splits inside herdr, smart-splits elsewhere. herdr-splits resizes by a
-- ratio of the pane and smart-splits by cells, so a fine step differs too.
local M = {}

local function plugin() return require(require("lib.herdr").inside() and "herdr-splits" or "smart-splits") end

---@param dir "left"|"down"|"up"|"right"
function M.move(dir) plugin()["move_cursor_" .. dir]() end

---@param dir "left"|"down"|"up"|"right"
---@param fine? boolean one cell, or one percent of a herdr pane
function M.resize(dir, fine)
    local amount = nil
    if fine then
        amount = require("lib.herdr").inside() and 0.01 or 1
    end
    plugin()["resize_" .. dir](amount)
end

return M
