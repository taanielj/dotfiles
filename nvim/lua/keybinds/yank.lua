-- <leader>y  Yank
local yank = require("lib.yank")

local function line_suffix()
    local first, last = yank.line_range()
    return first == last and (":" .. first) or (":" .. first .. "-" .. last)
end

local function remote_url() return require("lib.git").web_url(vim.fn.expand("%:p"), yank.line_range()) end

local function yank_remote_url()
    local url = remote_url()
    if url then
        yank.copy(url, "git URL")
    end
end

local function open_remote_url()
    local url = remote_url()
    if url then
        vim.ui.open(url)
    end
end

-- stylua: ignore
require("lib.keymap").rows({
    { "n",          "<leader>yb", function() yank.copy(vim.fn.expand("%:p"), "path") end,                     "Yank buffer absolute path" },
    { { "n", "v" }, "<leader>yl", function() yank.copy(vim.fn.expand("%:p") .. line_suffix(), "path:line") end, "Yank buffer path with line" },
    { "n",          "<leader>yh", function() require("ui.md2html").yank() end,                                  "Yank buffer as HTML" },
    { "v",          "<leader>yh", function() require("ui.md2html").yank(yank.line_range()) end,                 "Yank selection as HTML" },
    { { "n", "v" }, "<leader>yg", yank_remote_url,                                                              "Yank git URL for line" },
    { { "n", "v" }, "<leader>go", open_remote_url,                                                              "Open line in browser" },
})
