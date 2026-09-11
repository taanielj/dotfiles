local M = {}

-- Import sorting is a code action, not part of textDocument/formatting, and
-- the edit has to land before the format request goes out, so it is fetched
-- and applied synchronously rather than through vim.lsp.buf.code_action.
local function organize_imports(bufnr)
    if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })) then
        return
    end
    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", function(client)
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { diagnostics = {}, only = { "source.organizeImports" } }
        return params
    end, 2000)
    for client_id, response in pairs(results or {}) do
        local client = vim.lsp.get_client_by_id(client_id)
        for _, action in ipairs(response.result or {}) do
            -- `only` is a hint some servers ignore: marksman answers with its
            -- table-of-contents action regardless.
            if client and action.kind and vim.startswith(action.kind, "source.organizeImports") then
                if not action.edit and client:supports_method("codeAction/resolve") then
                    local resolved = client:request_sync("codeAction/resolve", action, 2000, bufnr)
                    action = resolved and resolved.result or action
                end
                if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                end
            end
        end
    end
end

-- mkview/loadview keep the folds across the rewrite.
function M.buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("mkview")
    organize_imports(bufnr)
    vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 5000 })
    vim.cmd("retab")
    vim.cmd("silent! loadview")
    vim.cmd("retab")
end

return M
