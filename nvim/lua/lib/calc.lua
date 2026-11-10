local M = {}

local NUMBER = "%-?%d+%.?%d*"

---@param expression string
---@param env? table
---@return number?
local function evaluate(expression, env)
    local chunk = load("return " .. expression, "calc", "t", vim.tbl_extend("keep", env or {}, { math = math }))
    if not chunk then
        return nil
    end
    local ok, value = pcall(chunk)
    if ok and type(value) == "number" and value == value and math.abs(value) ~= math.huge then
        return value
    end
end

local function format(value) return string.format("%.15g", value) end

local function is_number(text) return text:match("^%s*" .. NUMBER .. "%s*$") ~= nil end

---@class calc.Target
---@field row integer 0-based
---@field start integer 0-based
---@field stop integer 0-based, exclusive
---@field text string

---@param target calc.Target
local function replace(target, value)
    vim.api.nvim_buf_set_text(0, target.row, target.start, target.row, target.stop, { format(value) })
end

---The number under or after the cursor, the way <C-a> finds it.
---@return calc.Target?
local function number_under_cursor()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local init = 1
    while true do
        local start, stop = line:find(NUMBER, init)
        if not start then
            return nil
        end
        if line:sub(stop, stop) == "." then
            stop = stop - 1
        end
        if stop > col then
            return { row = row - 1, start = start - 1, stop = stop, text = line:sub(start, stop) }
        end
        init = stop + 1
    end
end

---@return calc.Target?
local function expression_on_line()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    local start = line:find("=", 1, true)
    if not start then
        return nil
    end
    local text = line:sub(start + 1)
    if is_number(text) or not evaluate(text) then
        return nil
    end
    return { row = row - 1, start = start, stop = #line, text = text }
end

---@return calc.Target?
local function operator_region()
    local from, to = vim.fn.getpos("'["), vim.fn.getpos("']")
    if from[2] ~= to[2] then
        return nil
    end
    local line = vim.fn.getline(from[2])
    local start, stop = from[3], math.min(to[3], #line)
    return { row = from[2] - 1, start = start - 1, stop = stop, text = line:sub(start, stop) }
end

local function apply(target, expression, env)
    local value = evaluate(expression, env)
    if value == nil then
        vim.notify("Not a number or expression: " .. expression, vim.log.levels.WARN)
        return
    end
    replace(target, value)
end

local function edit(target, op)
    vim.ui.input({ prompt = "= ", default = target.text }, function(expression)
        if not expression or expression == "" then
            return
        end
        -- Text typed after the number becomes the expression a dot-repeat applies
        if vim.startswith(expression, target.text) then
            op.expression = "x" .. expression:sub(#target.text + 1)
        end
        apply(target, expression)
    end)
end

-- The mappings run as the g@ operator, which makes `.` repeat them. A key
-- press stores its operation in `pending`. A dot-repeat finds `pending` empty
-- and reuses `last`.
local pending, last

function M.operatorfunc()
    local op = pending or last
    pending = nil
    if not op then
        return
    end
    last = op
    local target
    if op.mode == "x" then
        target = operator_region()
    elseif op.operator then
        target = number_under_cursor()
    else
        target = expression_on_line() or number_under_cursor()
    end
    if not target then
        vim.notify("No number here", vim.log.levels.WARN)
        return
    end
    if op.operator then
        apply(target, "x " .. op.operator .. " n", { x = evaluate(target.text), n = op.n })
    elseif not is_number(target.text) then
        apply(target, target.text)
    elseif op.expression then
        apply(target, op.expression, { x = tonumber(target.text) })
    else
        edit(target, op)
    end
end

local function as_operator(make)
    return function()
        pending = make()
        pending.mode = vim.fn.mode():match("[vV]") and "x" or "n"
        vim.go.operatorfunc = "v:lua.require'lib.calc'.operatorfunc"
        return pending.mode == "x" and "g@" or "g@l"
    end
end

---Evaluate the `KEY=expression` line or selected expression, otherwise edit the number in a box.
M.evaluate = as_operator(function() return {} end)

local defaults = { ["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2, ["^"] = 2 }

---Apply `operator` to the number under the cursor or selected, with the count as the operand.
---@param operator "+"|"-"|"*"|"/"|"^"
function M.operate(operator)
    return as_operator(
        function() return { operator = operator, n = vim.v.count > 0 and vim.v.count or defaults[operator] } end
    )
end

return M
