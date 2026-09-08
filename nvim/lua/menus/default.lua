-- The whole PopUp menu, replacing Neovim's own so rows that cannot apply
-- are left out instead of shown disabled. `ctx` comes from ui.menu.
local icons = require("ui.icons")

return function(ctx)
    local function open_in_terminal()
        local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
        vim.cmd("enew")
        vim.fn.jobstart({ vim.o.shell, "-c", "cd " .. vim.fn.shellescape(dir) .. " ; " .. vim.o.shell }, { term = true })
    end

    local function edit_config()
        vim.cmd("tabnew")
        vim.cmd("tcd " .. vim.fn.stdpath("config") .. " | edit init.lua")
    end

    local entries = {}
    local function add(entry, when)
        if when ~= false then
            entries[#entries + 1] = entry
        end
    end
    local function item(icon, name, cmd, when, mode)
        add({ name = icon .. "  " .. name, cmd = cmd, mode = mode }, when)
    end

    item(icons.browser, "Open in web browser", "gx", ctx.url)
    item(icons.definition, "Go to definition", vim.lsp.buf.definition, ctx.lsp)
    item(icons.code_action, "Code actions", vim.lsp.buf.code_action, ctx.lsp)
    item(icons.format, "Format buffer", vim.lsp.buf.format, ctx.lsp)
    add({
        name = icons.lsp .. "  LSP",
        items = {
            { name = "Go to implementation", cmd = vim.lsp.buf.implementation },
            { name = "Show references", cmd = vim.lsp.buf.references },
            { name = "Signature help", cmd = vim.lsp.buf.signature_help },
            { name = "Rename symbol", cmd = vim.lsp.buf.rename },
        },
    }, ctx.lsp)
    item(icons.diagnostics, "Show diagnostics", vim.diagnostic.open_float, ctx.diagnostics)
    item(icons.list, "All diagnostics", vim.diagnostic.setqflist, ctx.diagnostics)
    add({ separator = true }, ctx.url or ctx.lsp or ctx.diagnostics)

    item(icons.cut, "Cut", '"+x', nil, "v")
    item(icons.copy, "Copy", '"+y', nil, "v")
    item(icons.paste, "Paste", '"+gP', nil, "n")
    item(icons.paste, "Paste", '"+P', nil, "v")
    item(icons.delete, "Delete", "x", nil, "v")
    item(icons.select_all, "Select all", "<Cmd>normal! ggVG<CR>")
    item(icons.copy_all, "Copy buffer", "<Cmd>%y+<CR>", nil, "n")
    item(icons.erase, "Delete buffer contents", "<Cmd>%d<CR>", ctx.modifiable, "n")
    add({ separator = true })

    item(icons.inspect, "Inspect", "<Cmd>Inspect<CR>")
    item(icons.terminal, "Open in terminal", open_in_terminal)
    item(icons.config, "Edit config", edit_config)

    return entries
end
