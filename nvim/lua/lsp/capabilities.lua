local M = {}

function M.get()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    return vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
end

return M
