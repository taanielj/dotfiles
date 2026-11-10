-- A prompt about the cursor line or the visual selection, typed into the
-- Claude pane connected to this nvim. Works only inside herdr or the Herdr app,
-- which submit the text to the pane (lib/pane_host.lua).
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
    -- The input prompt shows the file name. Claude gets the absolute path, which
    -- resolves from any working directory.
    local path, name = vim.fn.expand("%:p"), vim.fn.expand("%:t")
    require("lib.claude_pane").pick(function(pane)
        vim.ui.input({ prompt = name .. span .. ": " }, function(instruction)
            if instruction and instruction ~= "" then
                -- The location goes last, so a slash command typed first still runs
                local text = table.concat({ instruction .. " " .. path .. span, found }, " - ")
                require("lib.pane_host")().submit_prompt(pane, text)
            end
        end)
    end)
end

return M
