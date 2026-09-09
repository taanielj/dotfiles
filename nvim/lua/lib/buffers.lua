local M = {}

---@return integer[] listed buffers
function M.listed()
    return vim.tbl_filter(function(buf)
        return vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
end

return M
