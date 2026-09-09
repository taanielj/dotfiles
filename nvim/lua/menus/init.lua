-- Which menu opens where. 'mousemodel' is popup_setpos, so a right-click
-- moves the cursor and opens PopUp with no mapping; PopUp is rebuilt for
-- what is under the cursor on every MenuPopup, replacing Neovim's handler,
-- which only disables rows. A bufferline tab is not a window, so it has a
-- separate hidden menu. Nothing is mapped on the mouse: a click while a
-- menu is open is pushed back and handled by normal mode directly, where
-- mappings do not apply.
local menu = require("ui.menu")

local M = {}

-- Filetypes with a menu of their own
local by_filetype = {
    ["neo-tree"] = "neotree",
    oil = "oil",
}

local function popup_rows()
    local spec = by_filetype[vim.bo.filetype]
    if spec then
        return require("menus." .. spec)()
    end
    return require("menus.default")(require("menus.context").get())
end

function M.popup_at_cursor()
    menu.show("PopUp", popup_rows(), { at_cursor = true })
end

---@param bufnr integer the clicked tab's buffer
function M.tab(bufnr)
    menu.show("]Buffer", require("menus.bufferline")({ bufnr = bufnr }))
end

function M.setup()
    vim.cmd("silent! aunmenu PopUp")
    pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")
    menu.define("PopUp", popup_rows()) -- never empty when a click lands

    vim.api.nvim_create_autocmd("MenuPopup", {
        group = vim.api.nvim_create_augroup("user_popupmenu", { clear = true }),
        callback = function()
            menu.define("PopUp", popup_rows()) -- a truthy return would delete the autocmd
        end,
    })
end

return M
