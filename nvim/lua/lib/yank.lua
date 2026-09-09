-- Copies to the system clipboard and says so.
local M = {}

---@param text string
---@param what string  named in the notification title
function M.copy(text, what)
    vim.fn.setreg("+", text)
    vim.notify(text, vim.log.levels.INFO, { title = "Yanked " .. what })
end

---The visual selection's line span, or the cursor line twice.
---@return integer, integer
function M.line_range()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        local first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then
            first, last = last, first
        end
        return first, last
    end
    local line = vim.fn.line(".")
    return line, line
end

return M
