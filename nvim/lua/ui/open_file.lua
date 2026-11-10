-- Opens files sent from outside nvim. The Herdr app's Files panel calls `open`
-- through this nvim's server socket (herdr/bin/herdr-open.sh).
local host = require("lib.pane_host")

local M = {}

---@param win integer
---@return boolean
local function is_file_window(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[buf].buftype == ""
        and not vim.b[buf].claude_draft
        and not vim.b[buf].claude_transcript
end

---@param path string
---@return integer 1, which tells herdr-open.sh that nvim opened the file
function M.open(path)
    local current = vim.api.nvim_get_current_win()
    if not is_file_window(current) then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if is_file_window(win) then
                vim.api.nvim_set_current_win(win)
                break
            end
        end
    end
    vim.cmd.drop(vim.fn.fnameescape(path))
    host().focus(assert(host().pane_id()))
    return 1
end

return M
