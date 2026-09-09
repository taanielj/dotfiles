local M = {}

---The first window showing a buffer of `filetype`, in the current tabpage or
---anywhere; nil when there is none.
---@param filetype string
---@param opts? { tabpage: boolean }
---@return integer?
function M.by_filetype(filetype, opts)
    local wins = opts and opts.tabpage and vim.api.nvim_tabpage_list_wins(0) or vim.api.nvim_list_wins()
    for _, win in ipairs(wins) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == filetype then
            return win
        end
    end
    return nil
end

return M
