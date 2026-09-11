local M = {}

---@return integer[] listed buffers
function M.listed()
    return vim.tbl_filter(function(buf) return vim.bo[buf].buflisted end, vim.api.nvim_list_bufs())
end

---@param bufnr integer
function M.is_file(bufnr) return vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= "" end

return M
