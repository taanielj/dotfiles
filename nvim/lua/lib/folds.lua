-- ufo keeps 'foldlevel' at 99 and opens and closes folds itself.
-- vim.b.fold_level records the buffer's fold depth, and nil means all folds are
-- open.
local M = {}

local function deepest()
    local max = 0
    for lnum = 1, vim.fn.line("$") do
        max = math.max(max, vim.fn.foldlevel(lnum))
    end
    return max
end

---@param level integer
function M.set_level(level)
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
        return M.set_level(vim.v.count)
    end
    M.set_level(math.min(vim.b.fold_level or math.huge, deepest()) + delta)
end

return M
