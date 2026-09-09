-- The session must be saved before :restart; auto-session restores it on the
-- next start.
local M = {}

function M.restart()
    local unsaved = {}
    for _, info in ipairs(vim.fn.getbufinfo({ bufmodified = 1, buflisted = 1 })) do
        if vim.bo[info.bufnr].buftype == "" then
            unsaved[#unsaved + 1] = info.name ~= "" and vim.fn.fnamemodify(info.name, ":~:.") or "[No Name]"
        end
    end
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
