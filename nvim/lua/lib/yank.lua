local M = {}

---@param text string
---@param what string  named in the notification title
---@param shown? string  notification body in place of `text`
function M.copy(text, what, shown)
    vim.fn.setreg("+", text)
    vim.notify(shown or text, vim.log.levels.INFO, { title = "Yanked " .. what })
end

---@return integer, integer
function M.selection_or_cursor_lines()
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
