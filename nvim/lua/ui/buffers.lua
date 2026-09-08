-- Closing keeps the window layout, and the last listed buffer going quits
-- nvim. Inside a diffview the view closes instead: its buffers are not ours.
local M = {}

local function listed()
    return vim.tbl_filter(function(buf)
        return vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
end

---@param opts? snacks.bufdelete.Opts
function M.close(opts)
    local diffview = require("ui.diffview")
    if not (opts and opts.buf) and diffview.is_open() then
        diffview.close()
        return
    end

    if #listed() <= 1 then
        vim.cmd((opts or {}).force and "qa!" or "qa")
        return
    end

    require("snacks.bufdelete").delete(opts)
end

return M
