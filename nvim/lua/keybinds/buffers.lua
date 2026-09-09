local map = require("lib.keymap").rows

map({
    -- <leader>b  Buffer
    { "n", "<leader>bn",                           "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n", "<leader>bp",                           "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n", "<Tab>",                                "<Cmd>BufferLineCycleNext<CR>",                  "Next buffer" },
    { "n", "<S-Tab>",                              "<Cmd>BufferLineCyclePrev<CR>",                  "Previous buffer" },
    { "n", "<leader>bh",                           "<Cmd>BufferLineMovePrev<CR>",                   "Move buffer left" },
    { "n", "<leader>bl",                           "<Cmd>BufferLineMoveNext<CR>",                   "Move buffer right" },
    { "n", "<leader>bP",                           "<Cmd>BufferLinePick<CR>",                       "Pick buffer" },
    { "n", "<leader>bt",                           "<Cmd>BufferLineTogglePin<CR>",                  "Pin buffer" },
    { "n", { "ZZ", "<leader>bq", "<leader>qb" },   function() require("ui.close_buffer").close() end,    "Save and close buffer" },
    { "n", "<leader>bch",                          "<Cmd>BufferLineCloseLeft<CR>",                  "Close buffers to the left" },
    { "n", "<leader>bcl",                          "<Cmd>BufferLineCloseRight<CR>",                 "Close buffers to the right" },
    { "n", "<leader>bca",                          "<Cmd>BufferLineCloseOthers<CR>",                "Close other buffers" },
    { "n", "<leader>bsd",                          "<Cmd>BufferLineSortByDirectory<CR>",            "Sort by directory" },
    { "n", "<leader>bst",                          "<Cmd>BufferLineSortByTabs<CR>",                 "Sort by tabs" },
    { "n", "<leader>bse",                          "<Cmd>BufferLineSortByExtension<CR>",            "Sort by extension" },

    -- <leader>q  Close
    { "n", "<leader>q!",                           function() require("ui.close_buffer").close({ force = true }) end, "Close buffer without saving" },
    { "n", "<leader>qa",                           "<Cmd>wa<CR><Cmd>qa<CR>",                        "Quit and save all" },
    { "n", "<leader>qfy",                          "<Cmd>qa!<CR>",                                  "Quit without saving?" },
})

-- The session must be saved before :restart; auto-session restores it on the
-- next start.
vim.keymap.set("n", "<leader>R", function()
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
end, { desc = "Restart nvim, keeping the session" })
