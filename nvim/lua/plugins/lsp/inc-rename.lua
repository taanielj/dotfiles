return {
    "smjonas/inc-rename.nvim",
    -- lazy's cmd stub has no preview callback, so a cmd trigger loses the preview on the first rename
    event = "LspAttach",
    opts = function()
        -- post_hook runs after the edit is applied, so record which buffers were dirty when :IncRename was typed
        local was_modified = {}
        vim.api.nvim_create_autocmd("CmdlineEnter", {
            pattern = ":",
            callback = function()
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    was_modified[buf] = vim.bo[buf].modified
                end
            end,
        })
        return {
            post_hook = function(result)
                local uris = vim.tbl_keys(result.changes or {})
                for _, change in ipairs(result.documentChanges or {}) do
                    if change.textDocument then table.insert(uris, change.textDocument.uri) end
                end
                for _, uri in ipairs(uris) do
                    local buf = vim.uri_to_bufnr(uri)
                    if not was_modified[buf] then
                        vim.api.nvim_buf_call(buf, function() vim.cmd("silent update") end)
                    end
                end
            end,
        }
    end,
}
