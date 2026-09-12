return {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = {},
    -- stylua: ignore
    keys = {
        { "<leader>S", mode = "n", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search and replace in project" },
        { "<leader>S", mode = "x", function() require("grug-far").with_visual_selection() end,                                   desc = "Search and replace selection in project" },
    },
}
