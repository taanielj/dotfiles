-- Inside herdr, lazygit is herdr's own popup, the plugin pane behind prefix+g,
-- so one lazygit looks the same from every pane; elsewhere it is lazygit.nvim.
local M = {}

function M.open()
    local herdr = require("lib.herdr")
    if not herdr.inside() then
        vim.cmd("LazyGit")
        return
    end
    herdr.run({
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
    })
end

return M
