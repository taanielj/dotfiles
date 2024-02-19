return {
    "altermo/ultimate-autopair.nvim",
    branch = "v0.6",
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
        require("ultimate-autopair").setup({})
    end,
}
