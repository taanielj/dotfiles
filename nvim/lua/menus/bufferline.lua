local icons = require("lib.icons")

return function(ctx)
    local bufnr = ctx.bufnr
    local name = vim.api.nvim_buf_get_name(bufnr)
    local buffers = require("ui.close_buffer")
    local others = #require("lib.buffers").listed() > 1
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
    local groups = require("bufferline.groups")
    local pinned = groups._is_pinned({ id = bufnr })
    local function toggle_pin()
        if pinned then
            groups.remove_element("pinned", { id = bufnr })
        else
            groups.add_element("pinned", { id = bufnr })
        end
        require("bufferline.ui").refresh()
    end

    local function close_others()
        for _, buf in ipairs(require("lib.buffers").listed()) do
            if buf ~= bufnr then
                buffers.close({ buf = buf })
            end
        end
    end

    local rows = require("lib.menu").rows()

    rows.item(icons.delete, "Close", function() buffers.close({ buf = bufnr }) end)
    rows.item(icons.close_all, "Close others", close_others, others)
    rows.item(icons.close_left, "Close to the left", close_tabs(1, index - 1), index > 1)
    rows.item(icons.close_right, "Close to the right", close_tabs(index + 1, #tabs), index > 0 and index < #tabs)
    rows.item(icons.pin, pinned and "Unpin" or "Pin", toggle_pin)
    rows.add({ separator = true })
    if name ~= "" then
        require("menus.file")(rows, name)
    end

    return rows.entries
end
