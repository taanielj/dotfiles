-- The session must be saved before :restart; auto-session restores it on the
-- next start.
local M = {}

---File buffers carrying unsaved changes, named as the messages show them.
---@return string[]
function M.unsaved()
    local names = {}
    for _, info in ipairs(vim.fn.getbufinfo({ bufmodified = 1, buflisted = 1 })) do
        if vim.bo[info.bufnr].buftype == "" then
            names[#names + 1] = info.name ~= "" and vim.fn.fnamemodify(info.name, ":~:.") or "[No Name]"
        end
    end
    return names
end

-- auto-session's own delete switches auto-save off for the rest of the instance
function M.forget()
    if vim.v.this_session ~= "" then
        vim.fn.delete(vim.v.this_session)
    end
end

function M.restart()
    local unsaved = M.unsaved()
    if #unsaved > 0 then
        vim.notify("Unsaved before restart: " .. table.concat(unsaved, ", "), vim.log.levels.WARN)
        return
    end

    require("auto-session").auto_save_session()

    -- noice's UI handler errors on the restart event, so it is detached first
    if package.loaded["noice"] then
        require("noice").disable()
    end
    vim.cmd.restart()
end

return M
