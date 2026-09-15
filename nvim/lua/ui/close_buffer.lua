-- Closing keeps the window layout, and the last listed buffer going quits
-- nvim, or shows the dashboard when neo-tree is open (ui/dashboard.lua).
-- Inside a diffview the view closes instead: its buffers are not ours.
local M = {}

---@class ui.close_buffer.Opts: snacks.bufdelete.Opts
---@field save? boolean

-- An unnamed buffer with changes asks where to write them; nothing happens
-- when the prompt is cancelled
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

---Back to an empty workspace: every listed buffer goes and the dashboard
---stands in. Unsaved work refuses the reset rather than prompting per buffer,
---so the answer is the same whichever buffer is current.
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

    -- The dashboard takes the window first, so no delete lands on the last one
    require("ui.dashboard").open()
    require("snacks.bufdelete").delete({ filter = function() return true end })
    session.forget()
end

return M
