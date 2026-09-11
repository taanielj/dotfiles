-- What the text buffer menu gates its rows on.
local M = {}

local symbol_captures = {
    variable = true,
    constant = true,
    parameter = true,
    property = true,
    field = true,
    ["function"] = true,
    method = true,
    constructor = true,
    type = true,
    module = true,
    namespace = true,
    attribute = true,
}

-- Without a parser any word counts as a symbol.
local function symbol_and_call(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return vim.fn.expand("<cword>"):match("^[%w_]+$") ~= nil, true
    end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    parser:parse({ row, row })

    local symbol = vim.iter(vim.treesitter.get_captures_at_cursor(0))
        :any(function(capture) return symbol_captures[capture:match("^[%a_]+")] == true end)
    local node = vim.treesitter.get_node()
    while node and not node:type():match("argument") do
        node = node:parent()
    end
    return symbol, node ~= nil
end

function M.get()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local symbol, in_call = symbol_and_call(bufnr)
    return {
        bufnr = bufnr,
        -- _get_urls() falls back to <cfile>, so any word would count
        url = vim.iter(vim.ui._get_urls()):any(function(url) return url:match("^%a[%w+.-]*://") ~= nil end),
        symbol = symbol,
        in_call = in_call,
        supports = function(method) return #vim.lsp.get_clients({ bufnr = bufnr, method = method }) > 0 end,
        line_diagnostics = #vim.diagnostic.get(bufnr, { lnum = row }) > 0,
        diagnostics = #vim.diagnostic.get(bufnr) > 0,
        modifiable = vim.bo[bufnr].modifiable,
        file = vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= "",
        test_file = require("lib.debug_test").in_test_file(bufnr),
        empty = vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "",
        clipboard = vim.fn.getreg("+") ~= "",
    }
end

return M
