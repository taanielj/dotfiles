return {
    "folke/which-key.nvim",
    dependencies = {
        "echasnovski/mini.icons",
    },
    event = "VeryLazy",
    opts = function()
        -- Mappings are read from Neovim directly; only the prefix labels need declaring
        return { spec = require("keybinds").groups }
    end,
}
