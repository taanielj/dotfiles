-- ufo keeps 'foldlevel' at 99 and opens and closes folds itself. This module
-- keeps the buffer's fold depth in vim.b.fold_level instead, nil meaning all
-- open.
local M = {}

local function deepest()
    local max = 0
    for lnum = 1, vim.fn.line("$") do
        max = math.max(max, vim.fn.foldlevel(lnum))
    end
    return max
end

---Open folds up to `level` deep and close the rest.
---@param level integer
function M.show(level)
    if level >= deepest() then
        require("ufo").openAllFolds()
        vim.b.fold_level = nil
    else
        level = math.max(level, 0)
        require("ufo").closeFoldsWith(level)
        vim.b.fold_level = level
    end
end

---A count picks the level outright; without one the level moves by `delta`.
---@param delta integer
function M.step(delta)
    if vim.v.count > 0 then
        return M.show(vim.v.count)
    end
    M.show(math.min(vim.b.fold_level or math.huge, deepest()) + delta)
end

return M
