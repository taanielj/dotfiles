local icons = require("ui.icons")

return function(ctx)
    local bufnr = ctx.bufnr
    local name = vim.api.nvim_buf_get_name(bufnr)
    local filename = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
    local buffers = require("ui.buffers")
    local others = #vim.fn.getbufinfo({ buflisted = 1 }) > 1
    local pinned = require("bufferline.groups")._is_pinned({ id = bufnr })

    local rows = require("ui.menu").rows()

    rows.item(icons.file, filename, function() vim.cmd("buffer " .. bufnr) end)
    rows.add({ separator = true })
    rows.item(icons.delete, "Close", function() buffers.close({ buf = bufnr }) end)
    rows.item(icons.split, "Close others", function() require("snacks.bufdelete").other({ buf = bufnr }) end, others)
    rows.item(icons.pin, pinned and "Unpin" or "Pin", function() vim.cmd("BufferLineTogglePin " .. bufnr) end)
    rows.add({ separator = true })
    rows.item(icons.clipboard, "Copy name", function()
        vim.fn.setreg("+", filename)
        vim.notify("Copied: " .. filename)
    end, name ~= "")

    return rows.entries
end
