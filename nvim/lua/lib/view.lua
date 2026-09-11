local M = {}

-- A view file ends with `doautoall SessionLoadPost`, which plugins restoring
-- windows from a session take for a session load.
function M.load()
    local eventignore = vim.o.eventignore
    vim.opt.eventignore:append("SessionLoadPost")
    vim.cmd("silent! loadview")
    vim.o.eventignore = eventignore
end

return M
