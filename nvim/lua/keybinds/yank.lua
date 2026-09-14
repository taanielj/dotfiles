-- <leader>y  Yank
local yank = require("lib.yank")

local function line_suffix()
    local first, last = yank.line_range()
    return first == last and (":" .. first) or (":" .. first .. "-" .. last)
end

---@param opts { permalink: boolean? }?
local function remote_url(opts)
    local first, last = yank.line_range()
    return require("lib.git").web_url(vim.fn.expand("%:p"), first, last, opts)
end

local function yank_remote_url(opts)
    local url = remote_url(opts)
    if url then
        yank.copy(url, "git URL")
    end
end

local function open_remote_url(opts)
    local url = remote_url(opts)
    if url then
        vim.ui.open(url)
    end
end

local permalink = { permalink = true }

-- stylua: ignore
require("lib.keymap").rows({
    { "n",          "<leader>yb", function() yank.copy(vim.fn.expand("%:p"), "path") end,                     "Yank buffer absolute path" },
    { { "n", "v" }, "<leader>yl", function() yank.copy(vim.fn.expand("%:p") .. line_suffix(), "path:line") end, "Yank buffer path with line" },
    { "n",          "<leader>yh", function() require("ui.md2html").yank() end,                                  "Yank buffer as HTML" },
    { "v",          "<leader>yh", function() require("ui.md2html").yank(yank.line_range()) end,                 "Yank selection as HTML" },
    { { "n", "v" }, "<leader>yg", function() yank_remote_url() end,                                             "Yank git URL for line" },
    { { "n", "v" }, "<leader>yG", function() yank_remote_url(permalink) end,                                    "Yank permalink for line" },
    { { "n", "v" }, "<leader>go", function() open_remote_url() end,                                             "Open line in browser" },
    { { "n", "v" }, "<leader>gO", function() open_remote_url(permalink) end,                                    "Open permalink in browser" },
})
