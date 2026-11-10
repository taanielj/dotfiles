-- Which menu opens where.
-- 'mousemodel' is popup_setpos, which makes a right-click move the cursor and
-- open PopUp without a mapping.
-- No mouse button is mapped because a click while a menu is open goes straight
-- to normal mode, where mappings don't apply.
local menu = require("lib.menu")

local M = {}

local menu_by_filetype = {
    ["neo-tree"] = "neotree",
    oil = "oil",
}

local function popup_rows()
    local spec = menu_by_filetype[vim.bo.filetype]
    if spec then
        return require("menus." .. spec)()
    end
    return require("menus.default")(require("menus.context").get())
end

function M.popup_at_cursor() menu.show("PopUp", popup_rows(), { at_cursor = true }) end

-- PopUp's rows describe a window. A bufferline tab gets the hidden ]Buffer menu.
---@param bufnr integer the clicked tab's buffer
function M.tab(bufnr) menu.show("]Buffer", require("menus.bufferline")({ bufnr = bufnr })) end

function M.setup()
    vim.cmd("silent! aunmenu PopUp")
    -- Neovim's MenuPopup handler only disables rows. user_popupmenu rebuilds
    -- PopUp for what is under the cursor instead.
    pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")
    menu.define("PopUp", popup_rows()) -- PopUp must exist before the first right-click

    vim.api.nvim_create_autocmd("MenuPopup", {
        group = vim.api.nvim_create_augroup("user_popupmenu", { clear = true }),
        callback = function()
            menu.define("PopUp", popup_rows()) -- a truthy return would delete the autocmd
        end,
    })
end

return M
