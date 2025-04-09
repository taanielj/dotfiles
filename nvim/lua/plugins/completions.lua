return {
    {
        "github/copilot.vim",
        config = function()
            vim.g.copilot_no_tab_map = true
            vim.keymap.set(
                "i",
                "<C-j>",
                'copilot#Accept("\\<CR>")',
                { expr = true, noremap = true, replace_keycodes = false }
            )
            vim.keymap.set("i", "<C-l>", "<Plug>(copilot-next)", { noremap = false })
            vim.keymap.set("i", "<C-h>", "<Plug>(copilot-previous)", { noremap = false })
            vim.keymap.set("i", "<C-Right>", "<Plug>(copilot-accept-word)", { noremap = false })
            vim.keymap.set("i", "<C-Left>", "<Plug>(copilot-accept-line)", { noremap = false })
            vim.keymap.set("n", "<Leader>cc", "<cmd>Copilot<CR>", { noremap = true, desc = "Copilot" })
            vim.keymap.set("n", "<Leader>cd", "<cmd>Copilot disable<CR>", { noremap = true, desc = "Copilot Disable" })
            vim.keymap.set("n", "<Leader>ce", "<cmd>Copilot enable<CR>", { noremap = true, desc = "Copilot Enable" })
        end,
    },
    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        opts = {},
    },
    {
        "hrsh7th/nvim-cmp",
        config = function()
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()
            cmp.setup({
                snippet = {
                    -- REQUIRED - you must specify a snippet engine
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                }, {}),
            })
        end,
    },
}
