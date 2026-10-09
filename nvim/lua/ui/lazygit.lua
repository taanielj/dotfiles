-- Inside herdr, lazygit is herdr's own popup, the plugin pane behind prefix+g,
-- so one lazygit looks the same from every pane; elsewhere it is snacks' float.
local M = {}

---@return snacks.image.Placement[]
local function image_placements()
    local placement = package.loaded["snacks.image.placement"]
    if not placement then
        return {}
    end
    -- snacks keeps its placements private; Placement.clean is the one function that closes over them
    for i = 1, math.huge do
        local name, by_buf = debug.getupvalue(placement.clean, i)
        if name == nil then
            return {}
        end
        if name == "placements" then
            local list = {}
            for _, by_id in pairs(by_buf) do
                vim.list_extend(list, vim.tbl_values(by_id))
            end
            return list
        end
    end
end

-- herdr draws kitty images above its popups, and clears them only on its own prefix key
local function hide_images_until_focus()
    local hidden = image_placements()
    for _, p in ipairs(hidden) do
        p:hide()
    end
    vim.api.nvim_create_autocmd("FocusGained", {
        once = true,
        callback = function()
            for _, p in ipairs(hidden) do
                p:show()
            end
        end,
    })
end

function M.open()
    local herdr = require("lib.herdr")
    if not herdr.inside() then
        Snacks.lazygit()
        return
    end
    hide_images_until_focus()
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
