-- Buffer closing that keeps the window layout, and exits when the last listed
-- buffer goes, which is what nvim-bufdel's quit option did.
local M = {}

local function listed()
    return vim.tbl_filter(function(buf)
        return vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
end

---@param opts? snacks.bufdelete.Opts
function M.close(opts)
    if #listed() <= 1 then
        vim.cmd((opts or {}).force and "qa!" or "qa")
        return
    end

    require("snacks.bufdelete").delete(opts)
end

return M
