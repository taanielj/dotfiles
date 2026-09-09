-- A diffview is closed as a whole, like ZZ and <leader>bq do, since :q on
-- one of its windows leaves the rest of the view behind.
vim.keymap.set("ca", "q", function()
    if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q" and require("ui.diffview").is_open() then
        return "DiffviewClose"
    end
    return "q"
end, { expr = true })

-- Up and Down walk directories, Left and Right walk the list
local swap = {
    ["<Up>"] = "<Left>",
    ["<Down>"] = "<Right>",
    ["<Left>"] = "<Up>",
    ["<Right>"] = "<Down>",
}
for key, replacement in pairs(swap) do
    vim.keymap.set("c", key, function() return vim.fn.pumvisible() == 1 and replacement or key end, { expr = true })
end
