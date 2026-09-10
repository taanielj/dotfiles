-- Inside herdr, lazygit is herdr's own popup, the plugin pane behind prefix+g,
-- so one lazygit looks the same from every pane; elsewhere it is lazygit.nvim.
local M = {}

function M.open()
    local herdr = require("lib.herdr")
    if not herdr.inside() then
        vim.cmd("LazyGit")
        return
    end
    vim.system({
        herdr.bin(),
        "plugin",
        "pane",
        "open",
        "--plugin",
        "lazygit",
        "--entrypoint",
        "lazygit",
        "--cwd",
        vim.fn.getcwd(),
        "--focus",
    }, { text = true }, function(res)
        if res.code ~= 0 then
            vim.schedule(
                function() vim.notify("herdr: " .. vim.trim(res.stderr or res.stdout or ""), vim.log.levels.ERROR) end
            )
        end
    end)
end

return M
