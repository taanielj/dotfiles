local icons = require("ui.icons")

return function(ctx)
    local bufnr = ctx.bufnr
    local name = vim.api.nvim_buf_get_name(bufnr)
    local filename = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
    local buffers = require("ui.buffers")
    local others = #vim.fn.getbufinfo({ buflisted = 1 }) > 1
    local tabs = require("bufferline").get_elements().elements
    local index = 0
    for i, tab in ipairs(tabs) do
        if tab.id == bufnr then
            index = i
        end
    end
    local function close_tabs(from, to)
        return function()
            for i = from, to do
                buffers.close({ buf = tabs[i].id })
            end
        end
    end
    local pinned = require("bufferline.groups")._is_pinned({ id = bufnr })

    local rows = require("ui.menu").rows()

    rows.item(icons.delete, "Close", function() buffers.close({ buf = bufnr }) end)
    rows.item(icons.close_all, "Close others", function() require("snacks.bufdelete").other({ buf = bufnr }) end, others)
    rows.item(icons.close_left, "Close to the left", close_tabs(1, index - 1), index > 1)
    rows.item(icons.close_right, "Close to the right", close_tabs(index + 1, #tabs), index > 0 and index < #tabs)
    rows.item(icons.pin, pinned and "Unpin" or "Pin", function() vim.cmd("BufferLineTogglePin " .. bufnr) end)
    rows.add({ separator = true })
    if name ~= "" then
        require("menus.file")(rows, name)
    end

    return rows.entries
end
