-- In charwise visual mode v grows the selection to the enclosing treesitter
-- node and V shrinks it back, leaving visual mode once the stack is empty.
-- A bracketed node is two steps: its contents, then with the brackets.
-- Linewise and blockwise visual keep their native v and V.
local M = {}

---@class select_node.Step
---@field node TSNode
---@field inner boolean without the surrounding pair

local stack = {} ---@type select_node.Step[]
vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("select_node", { clear = true }),
    pattern = "v:*",
    callback = function() stack = {} end,
})

local pairs_ = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }

-- The opening and closing children, when the node is wrapped in a pair
local function brackets(node)
    local first, last = node:child(0), node:child(node:child_count() - 1)
    if first and last and first ~= last and pairs_[first:type()] == last:type() then
        return first, last
    end
end

-- End columns are exclusive, so a range ending at column 0 of a later line
-- is brought back to the end of the line before
---@param step select_node.Step
local function range(step)
    local sr, sc, er, ec
    if step.inner then
        local first, last = brackets(step.node)
        _, _, sr, sc = first:range()
        er, ec = last:range()
    else
        sr, sc, er, ec = step.node:range()
    end
    if ec == 0 and er > sr then
        er = er - 1
        ec = #vim.fn.getline(er + 1)
    end
    return sr, sc, er, ec
end

-- Moves both ends without leaving visual mode
---@param step select_node.Step
local function select(step)
    local sr, sc, er, ec = range(step)
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
end

---@param step select_node.Step
local function covers(step)
    local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
    local sr, sc, er, ec =
        math.min(s[2], e[2]) - 1, math.min(s[3], e[3]) - 1, math.max(s[2], e[2]) - 1, math.max(s[3], e[3])
    local nsr, nsc, ner, nec = range(step)
    return (nsr < sr or (nsr == sr and nsc <= sc))
        and (ner > er or (ner == er and nec >= ec))
        and not (nsr == sr and nsc == sc and ner == er and nec == ec)
end

function M.grow()
    local top = stack[#stack]
    local node = top and top.node
    if top and top.inner then
        top = { node = node, inner = false }
    else
        node = node and node:parent() or vim.treesitter.get_node()
        top = nil
        while node and not top do
            for _, inner in ipairs({ true, false }) do
                local step = { node = node, inner = inner }
                if not top and (not inner or brackets(node)) and covers(step) then
                    top = step
                end
            end
            node = node:parent()
        end
    end
    if top then
        table.insert(stack, top)
        select(top)
    end
end

function M.shrink()
    table.remove(stack)
    if stack[#stack] then
        select(stack[#stack])
    else
        vim.cmd("normal! \27")
    end
end

-- The key itself outside charwise visual, so V still means linewise there
---@param key "v"|"V"
function M.map(key)
    local action = key == "v" and "grow" or "shrink"
    return function()
        if vim.fn.mode() ~= "v" then
            return key
        end
        return "<Cmd>lua require('lib.select_node')." .. action .. "()<CR>"
    end
end

return M
