local buf_context = vim.g.menu_context or {}
local bufnr = buf_context.bufnr
local bufname = vim.api.nvim_buf_get_name(bufnr or 0)
local filename = vim.fn.fnamemodify(bufname, ":t")

local function noop()
    vim.notify("Placeholder action for buffer: " .. filename)
end

return {
    { name = "󰈔  Open buffer '" .. filename .. "'", cmd = noop, rtxt = "o" },
    { name = "  Dummy Split", cmd = noop, rtxt = "s" },
    { name = "  Dummy VSplit", cmd = noop, rtxt = "v" },
    { name = "separator" },
    { name = "  Close buffer", cmd = function()
        require("bufdel").bufdel(bufnr)
    end, rtxt = "d" },
    { name = "󰐃  Toggle pin", cmd = function()
        vim.cmd("BufferLineTogglePin " .. bufnr)
    end, rtxt = "p" },
    { name = "󰉿  Copy buffer name", cmd = function()
        vim.fn.setreg("+", filename)
        vim.notify("Copied: " .. filename)
    end, rtxt = "y" },
}
