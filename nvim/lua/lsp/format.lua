local M = {}

-- Import sorting is a code action, separate from textDocument/formatting.
-- The import edit must apply before the format request goes out, and
-- vim.lsp.buf.code_action is asynchronous.
local function organize_imports(bufnr)
    if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })) then
        return
    end
    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", function(client)
        return vim.tbl_extend("force", vim.lsp.util.make_range_params(0, client.offset_encoding), {
            context = { diagnostics = {}, only = { "source.organizeImports" } },
        })
    end, 2000)
    for client_id, response in pairs(results or {}) do
        local client = vim.lsp.get_client_by_id(client_id)
        for _, action in ipairs(response.result or {}) do
            -- `only` is a hint some servers ignore. marksman answers with its
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

function M.has_formatter(bufnr)
    -- PopUp's rows are first built before lazy.nvim loads conform
    local ok, conform = pcall(require, "conform")
    if not ok then
        return false
    end
    local formatters, lsp = conform.list_formatters_to_run(bufnr)
    return #formatters > 0 or lsp
end

-- mkview/loadview keep the folds across the rewrite.
function M.buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("mkview")
    organize_imports(bufnr)
    -- A parse error arrives as an RPC error dump. Show only its message.
    require("conform").format({ bufnr = bufnr, timeout_ms = 5000, quiet = true }, function(err)
        if err then
            vim.notify(err:match('message = "(.*)"$') or err, vim.log.levels.WARN)
        end
    end)
    vim.cmd("retab")
    require("lib.view").load()
    vim.cmd("retab")
end

return M
