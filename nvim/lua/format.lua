local M = {}

-- ruff formats through the LSP too, so it is filtered out in favour of black
-- and isort from none-ls. mkview/loadview keep the folds across the rewrite.
function M.buffer()
    vim.cmd("mkview")
    vim.lsp.buf.format({
        timeout_ms = 5000,
        filter = function(client)
            return client.name ~= "ruff"
        end,
    })
    vim.cmd("retab")
    vim.cmd("silent! loadview")
    vim.cmd("retab")
end

return M
