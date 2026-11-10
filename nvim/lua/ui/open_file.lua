-- Files sent to this nvim from outside: the Herdr app's Files panel calls
-- `open` through this nvim's server socket (herdr/bin/herdr-open.sh).
local host = require("lib.pane_host")

local M = {}

---@param win integer
---@return boolean the window edits files: not floating, a tree, a terminal or Claude's draft and transcript splits
local function edits(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[buf].buftype == ""
        and not vim.b[buf].claude_draft
        and not vim.b[buf].claude_transcript
end

---Opens the file in the current window if it edits files, else in the first
---such window of this tabpage, and focuses this nvim's pane.
---@param path string
---@return integer 1, which the caller takes as nvim having it
function M.open(path)
    local current = vim.api.nvim_get_current_win()
    if not edits(current) then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if edits(win) then
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
