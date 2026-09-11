-- A prompt about the cursor line or the visual selection, typed into the
-- Claude pane connected to this nvim. Inside herdr only: herdr-agents.nvim
-- finds the pane, `herdr agent prompt` submits the text there.
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

---@param text string
local function submit(text)
    local provider = require("herdr-agents.claude").provider
    local pane = provider and provider.pane()
    if not pane then
        vim.notify("No Claude pane for this nvim", vim.log.levels.WARN)
        return
    end
    local herdr = require("lib.herdr")
    vim.system({ herdr.bin(), "agent", "prompt", pane, text }, { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("herdr: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        end
    end)
end

function M.prompt()
    local first, last = require("lib.yank").line_range()
    local span, found = lines(first, last), diagnostics(first, last)
    if vim.fn.mode():match("[vV\22]") then
        vim.cmd("normal! \27")
    end
    -- The short name is for the eye; Claude gets the full path, which resolves
    -- from wherever its pane is
    local path = vim.fn.expand("%:p")
    vim.ui.input({ prompt = vim.fn.expand("%:t") .. span .. ": " }, function(instruction)
        if instruction and instruction ~= "" then
            submit(table.concat({ path .. span .. ": " .. instruction, found }, " - "))
        end
    end)
end

return M
