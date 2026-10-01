-- A prompt about the cursor line or the visual selection, typed into the
-- Claude pane connected to this nvim. Inside herdr only: `herdr agent prompt`
-- submits the text there.
local M = {}

---@param first integer
---@param last integer
---@return string ":first" or ":first-last"
local function lines(first, last)
    if first == last then
        return (":%d"):format(first)
    end
    return (":%d-%d"):format(first, last)
end

---Diagnostics on the selected lines, one line of text, or nil when there are none.
---@param first integer
---@param last integer
---@return string?
local function diagnostics(first, last)
    local items = {}
    for _, d in ipairs(vim.diagnostic.get(0)) do
        local line = d.lnum + 1
        if line >= first and line <= last then
            local tag = {}
            if d.source then
                tag[#tag + 1] = d.source
            end
            if d.code then
                tag[#tag + 1] = tostring(d.code)
            end
            items[#items + 1] = ("%d [%s] %s"):format(line, table.concat(tag, " "), d.message)
        end
    end
    return #items > 0 and ("diagnostics: " .. table.concat(items, "; ")) or nil
end

function M.prompt()
    local first, last = require("lib.yank").line_range()
    local span, found = lines(first, last), diagnostics(first, last)
    if vim.fn.mode():match("[vV\22]") then
        vim.cmd("normal! \27")
    end
    -- The short name is for the eye; Claude gets the full path, which resolves
    -- from wherever its pane is
    local path, name = vim.fn.expand("%:p"), vim.fn.expand("%:t")
    require("lib.claude_pane").pick(function(pane)
        vim.ui.input({ prompt = name .. span .. ": " }, function(instruction)
            if instruction and instruction ~= "" then
                local text = table.concat({ path .. span .. ": " .. instruction, found }, " - ")
                require("lib.herdr").run({ "agent", "prompt", pane, text })
            end
        end)
    end)
end

return M
