-- ================
-- <leader>y  Yank
-- ================

local yank = require("lib.yank")

local function line_suffix()
    local first, last = yank.line_range()
    return first == last and (":" .. first) or (":" .. first .. "-" .. last)
end

vim.keymap.set("n", "<leader>yb", function()
    yank.copy(vim.fn.expand("%:p"), "path")
end, { desc = "Yank buffer absolute path" })

vim.keymap.set({ "n", "v" }, "<leader>yl", function()
    yank.copy(vim.fn.expand("%:p") .. line_suffix(), "path:line")
end, { desc = "Yank buffer path with line" })

vim.keymap.set("n", "<leader>yh", function()
    require("md2html").yank()
end, { desc = "Yank buffer as HTML" })

vim.keymap.set("v", "<leader>yh", function()
    require("md2html").yank(yank.line_range())
end, { desc = "Yank selection as HTML" })

-- The origin URL for the file, with the line or selection anchored.
local function remote_url()
    return require("lib.git").web_url(vim.fn.expand("%:p"), yank.line_range())
end

vim.keymap.set({ "n", "v" }, "<leader>yg", function()
    local url = remote_url()
    if url then
        yank.copy(url, "git URL")
    end
end, { desc = "Yank git URL for line" })

vim.keymap.set({ "n", "v" }, "<leader>go", function()
    local url = remote_url()
    if url then
        vim.ui.open(url)
    end
end, { desc = "Open line in browser" })
