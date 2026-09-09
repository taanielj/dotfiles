return {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
        "tpope/vim-dadbod",
        "kristijanhusak/vim-dadbod-completion",
    },
    -- Lazy-load on SQL buffers (so completion attaches) or on any trigger below.
    ft = { "sql", "mysql", "plsql", "bigquery", "sqlite" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    -- Single leaf mapping: instant toggle, no prefix ambiguity.
    keys = {
        { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Dadbod: toggle UI" },
    },
    init = function()
        vim.g.db_ui_use_nerd_fonts = 1
        vim.g.db_ui_show_database_icon = 1
        vim.g.db_ui_win_position = "left"
        vim.g.db_ui_winwidth = 35
        -- Never auto-run a query just because the buffer was written.
        vim.g.db_ui_execute_on_save = 0

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("dadbod_sql_keys", { clear = true }),
            pattern = { "sql", "mysql", "plsql" },
            callback = function(ev)
                local map = require("lib.keymap").buffer(ev.buf)
                map("n", "<leader>x", "<cmd>%DB<cr>", "SQL: execute whole buffer")
                map("n", "<leader>X", "<cmd>.DB<cr>", "SQL: execute current line")
                map("x", "<leader>x", ":DB<cr>", "SQL: execute selection")
            end,
        })
    end,
}
