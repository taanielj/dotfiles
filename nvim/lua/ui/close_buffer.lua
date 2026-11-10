-- Closes a buffer and keeps the window layout.
-- - Closing the last listed buffer quits nvim, or opens the dashboard when
--   neo-tree is open (ui/dashboard.lua).
-- - Inside a diffview, closes the whole diffview, which manages its own buffers.
local M = {}

---@class ui.close_buffer.Opts: snacks.bufdelete.Opts
---@field save? boolean

-- Cancelling the Save as prompt cancels the close too
local function save(buf, done)
    if vim.bo[buf].buftype ~= "" or vim.bo[buf].readonly or not vim.bo[buf].modified then
        return done()
    end
    if require("lib.buffers").is_file(buf) then
        vim.api.nvim_buf_call(buf, function() vim.cmd.update() end)
        return done()
    end
    vim.ui.input({ prompt = "Save as (Esc to cancel): ", completion = "file" }, function(name)
        if not name or name == "" then
            return
        end
        vim.api.nvim_buf_call(buf, function() vim.cmd("write " .. vim.fn.fnameescape(name)) end)
        done()
    end)
end

local function close(opts, buf)
    local buffers = require("lib.buffers")
    if vim.bo[buf].buflisted and #buffers.listed() <= 1 then
        local dashboard = require("ui.dashboard")
        if dashboard.tree_open() then
            dashboard.open()
            vim.cmd((opts.force and "bdelete! " or "bdelete ") .. buf)
            require("ui.session").forget()
            return
        end
        vim.cmd(opts.force and "qa!" or "qa")
        return
    end

    require("snacks.bufdelete").delete(opts)
end

---@param opts? ui.close_buffer.Opts
function M.close(opts)
    opts = opts or {}
    local diffview = require("ui.diffview")
    if not opts.buf and diffview.is_open() then
        diffview.close()
        return
    end

    local buf = opts.buf or vim.api.nvim_get_current_buf()
    if opts.save then
        save(buf, function() close(opts, buf) end)
    else
        close(opts, buf)
    end
end

---Refuses when any buffer is unsaved, whichever buffer is current.
function M.close_all()
    local session = require("ui.session")
    local unsaved = session.unsaved()
    if #unsaved > 0 then
        vim.notify("Unsaved: " .. table.concat(unsaved, ", "), vim.log.levels.WARN)
        return
    end

    local diffview = require("ui.diffview")
    if diffview.is_open() then
        diffview.close()
    end

    -- The dashboard opens first, to keep a buffer in the window while bufdelete
    -- removes the rest
    require("ui.dashboard").open()
    require("snacks.bufdelete").delete({ filter = function() return true end })
    session.forget()
end

return M
