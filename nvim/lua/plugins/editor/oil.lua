return {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
        default_file_explorer = false,
        skip_confirm_for_simple_edits = true,
        prompt_save_on_select_new_entry = false,
        keymaps = {
            ["<BS>"] = "actions.parent",
            ["<C-s>"] = false,
            ["<C-h>"] = false,
        },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    event = "BufReadCmd oil://*",
}
