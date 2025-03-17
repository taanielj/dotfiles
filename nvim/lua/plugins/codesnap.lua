local save_path = "~/git/codesnap"
return {
    "mistricky/codesnap.nvim",
    build = "make build_generator",
    keys = {
        { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
        { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in " .. save_path },
    },
    opts = {
        save_path = save_path,
        has_breadcrumbs = true,
        bg_theme = "summer",
        editor_font_family = "JetBrainsMono Nerd Font",
        watermark = "",
    },
}
