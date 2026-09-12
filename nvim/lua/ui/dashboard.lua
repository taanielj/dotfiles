-- With neo-tree open, the dashboard stands in for the last file instead of
-- nvim quitting or the tree being left alone. Without it, closing quits.
local M = {}

local function is_tree(win) return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" end

local function normal_windows(except)
    return vim.tbl_filter(
        function(win) return win ~= except and vim.api.nvim_win_get_config(win).relative == "" end,
        vim.api.nvim_tabpage_list_wins(0)
    )
end

function M.tree_open()
    for _, win in ipairs(normal_windows()) do
        if is_tree(win) then
            return true
        end
    end
    return false
end

---@param closing? integer a window still listed while its WinClosed runs
function M.only_tree_left(closing)
    local wins = normal_windows(closing)
    if #wins == 0 then
        return false
    end
    for _, win in ipairs(wins) do
        if not is_tree(win) then
            return false
        end
    end
    return true
end

-- In the current window; without one the dashboard opens as a float
function M.open() Snacks.dashboard({ win = 0 }) end

function M.open_beside_tree()
    vim.cmd("rightbelow vnew")
    Snacks.dashboard({ win = 0, buf = 0 })
end

return M
