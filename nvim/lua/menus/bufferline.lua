local icons = require("ui.icons")

return function(ctx)
    local bufnr = ctx.bufnr
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    local buffers = require("ui.buffers")

    local function item(icon, name, cmd)
        return { name = icon .. "  " .. name, cmd = cmd }
    end

    return {
        item(icons.file, filename, function() vim.cmd("buffer " .. bufnr) end),
        { separator = true },
        item(icons.delete, "Close", function() buffers.close({ buf = bufnr }) end),
        item(icons.split, "Close others", function() require("snacks.bufdelete").other({ buf = bufnr }) end),
        item(icons.pin, "Toggle pin", function() vim.cmd("BufferLineTogglePin " .. bufnr) end),
        { separator = true },
        item(icons.clipboard, "Copy name", function()
            vim.fn.setreg("+", filename)
            vim.notify("Copied: " .. filename)
        end),
    }
end
