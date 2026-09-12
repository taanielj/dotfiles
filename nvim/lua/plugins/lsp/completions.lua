return {
    {
        "github/copilot.vim",
        event = "InsertEnter",
        cmd = "Copilot",
        init = function() vim.g.copilot_no_tab_map = true end,
    },
    {
        "saghen/blink.cmp",
        event = "InsertEnter",
        dependencies = { "saghen/blink.lib", "rafamadriz/friendly-snippets" },
        build = function() require("blink.cmp").build():pwait() end,
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = "enter",
                ["<C-k>"] = {}, -- C-hjkl move between panes
            },
            completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 } },
            cmdline = {
                -- The preset walks the list with Left and Right; Up and Down walk directories
                keymap = {
                    preset = "cmdline",
                    ["<Down>"] = { "accept", "fallback" },
                    ["<Up>"] = {
                        function(cmp)
                            if not cmp.is_menu_visible() then
                                return false
                            end
                            local line = vim.fn.getcmdline()
                            local parent = line:gsub("[^/ ]+/?$", "")
                            if parent == line then
                                return false
                            end
                            vim.fn.setcmdline(parent)
                            return cmp.show()
                        end,
                        "fallback",
                    },
                },
                completion = { menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end } },
            },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            fuzzy = { implementation = "rust" },
        },
        opts_extend = { "sources.default" },
    },
}
