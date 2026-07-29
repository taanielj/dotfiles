return {
    "alexpasmantier/pymple.nvim",
    ft = "python",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    build = ":PympleBuild",
    opts = {
        python = {
            root_markers = { "pyproject.toml", "setup.py", ".git", "manage.py" },
            virtual_env_names = { ".venv" },
        },
        keymaps = {
            resolve_import_under_cursor = { keys = "<leader>li", desc = "Resolve import" },
        },
    },
}
