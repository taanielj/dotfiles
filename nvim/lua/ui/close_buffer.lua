-- Closing keeps the window layout, and the last listed buffer going quits
-- nvim. Inside a diffview the view closes instead: its buffers are not ours.
local M = {}

---@class ui.close_buffer.Opts: snacks.bufdelete.Opts
---@field save? boolean

---@param opts? ui.close_buffer.Opts
function M.close(opts)
    opts = opts or {}
    local diffview = require("ui.diffview")
    if not opts.buf and diffview.is_open() then
        diffview.close()
        return
    end

    local buffers = require("lib.buffers")
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    if opts.save and buffers.is_file(buf) and not vim.bo[buf].readonly then
        vim.api.nvim_buf_call(buf, function() vim.cmd.update() end)
    end

    if vim.bo[buf].buflisted and #buffers.listed() <= 1 then
        vim.cmd(opts.force and "qa!" or "qa")
        return
    end

    require("snacks.bufdelete").delete(opts)
end

return M
