-- v in visual mode grows the selection to the smallest treesitter node that
-- is bigger than it; repeated presses climb the tree.
local M = {}

local function selection()
    local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
        s, e = e, s
    end
    return s[2] - 1, s[3] - 1, e[2] - 1, e[3] - 1
end

local function contains(node, sr, sc, er, ec)
    local nsr, nsc, ner, nec = node:range()
    -- node end columns are exclusive, the selection's is inclusive
    nec = nec - 1
    local starts_before = nsr < sr or (nsr == sr and nsc <= sc)
    local ends_after = ner > er or (ner == er and nec >= ec)
    return starts_before and ends_after
end

local function same(node, sr, sc, er, ec)
    local nsr, nsc, ner, nec = node:range()
    return nsr == sr and nsc == sc and ner == er and nec - 1 == ec
end

function M.grow()
    local sr, sc, er, ec = selection()
    local ok, node = pcall(vim.treesitter.get_node, { pos = { sr, sc } })
    if not ok or not node then
        return
    end
    while node and not (contains(node, sr, sc, er, ec) and not same(node, sr, sc, er, ec)) do
        node = node:parent()
    end
    if not node then
        return
    end
    local nsr, nsc, ner, nec = node:range()
    -- a node ending at column 0 of a later line ends on the line before
    if nec == 0 and ner > nsr then
        ner = ner - 1
        nec = #vim.fn.getline(ner + 1)
    end
    vim.cmd("normal! \27")
    vim.api.nvim_win_set_cursor(0, { nsr + 1, nsc })
    vim.cmd("normal! v")
    vim.api.nvim_win_set_cursor(0, { ner + 1, math.max(nec - 1, 0) })
end

return M
