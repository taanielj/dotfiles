local M = {}

---@param rel string path under mason's install root, e.g. "bin/jdtls"
function M.path(rel)
    return vim.fs.joinpath(vim.fn.stdpath("data"), "mason", rel)
end

return M
