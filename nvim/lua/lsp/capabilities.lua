local M = {}

---Client capabilities for every server: completion through nvim-cmp, and
---folding ranges, which Neovim does not advertise by default and nvim-ufo
---needs.
function M.get()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
    capabilities.textDocument.foldingRange = {
        dynamicRegistration = true,
        lineFoldingOnly = true,
    }
    return capabilities
end

return M
