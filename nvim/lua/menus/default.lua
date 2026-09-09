-- The text buffer menu; `ctx` is menus.context.get().
local icons = require("ui.icons")
local menu = require("ui.menu")

return function(ctx)
    local function edit_config()
        vim.cmd.tabnew()
        vim.cmd.tcd(vim.fn.fnameescape(vim.fn.stdpath("config")))
        vim.cmd.edit("init.lua")
    end

    local rows = menu.rows()

    rows.item(icons.browser, "Open in web browser", "gx", ctx.url)
    rows.item(icons.definition, "Go to definition", vim.lsp.buf.definition, ctx.symbol and ctx.supports("textDocument/definition"))
    rows.item(icons.implementation, "Go to implementation", vim.lsp.buf.implementation, ctx.symbol and ctx.supports("textDocument/implementation"))
    rows.item(icons.references, "Show references", vim.lsp.buf.references, ctx.symbol and ctx.supports("textDocument/references"))
    rows.item(icons.rename, "Rename symbol", vim.lsp.buf.rename, ctx.symbol and ctx.modifiable and ctx.supports("textDocument/rename"))
    rows.item(icons.signature, "Signature help", vim.lsp.buf.signature_help, ctx.in_call and ctx.supports("textDocument/signatureHelp"))
    rows.item(icons.code_action, "Code actions", vim.lsp.buf.code_action, ctx.supports("textDocument/codeAction"))
    rows.item(icons.format, "Format buffer", require("lsp.format").buffer, ctx.modifiable and ctx.supports("textDocument/formatting"))
    rows.item(icons.diagnostics, "Show diagnostics", vim.diagnostic.open_float, ctx.line_diagnostics)
    rows.item(icons.list, "All diagnostics", vim.diagnostic.setqflist, ctx.diagnostics)
    rows.add({ separator = true })

    rows.item(icons.cut, "Cut", '"+x', ctx.modifiable, "v")
    rows.item(icons.copy, "Copy", '"+y', nil, "v")
    rows.item(icons.paste, "Paste", '"+gP', ctx.modifiable and ctx.clipboard, "n")
    rows.item(icons.paste, "Paste", '"+P', ctx.modifiable and ctx.clipboard, "v")
    rows.item(icons.delete, "Delete", "x", ctx.modifiable, "v")
    rows.item(icons.select_all, "Select all", "<Cmd>normal! ggVG<CR>", not ctx.empty)
    rows.item(icons.copy_all, "Copy buffer", "<Cmd>%y+<CR>", not ctx.empty, "n")
    rows.add({ separator = true })

    rows.item(icons.inspect, "Inspect", "<Cmd>Inspect<CR>")
    rows.item(icons.config, "Edit config", edit_config)

    return rows.entries
end
