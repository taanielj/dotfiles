return {
    {
        "windwp/nvim-autopairs",
        dependencies = { "hrsh7th/nvim-cmp" },
        event = "InsertEnter",
        opts = {
            disable_in_macro = true,
            disable_in_replace_mode = true,
        },
        config = function()
            require("nvim-autopairs").setup()
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },
}
