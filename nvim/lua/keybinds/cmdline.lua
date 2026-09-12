-- A diffview is closed as a whole, like ZZ and <leader>bq do, since :q on
-- one of its windows leaves the rest of the view behind.
vim.keymap.set("ca", "q", function()
    if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q" and require("ui.diffview").is_open() then
        return "DiffviewClose"
    end
    return "q"
end, { expr = true })
