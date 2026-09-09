return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
        "s1n7ax/nvim-window-picker",
    },
    config = function()
        require("window-picker").setup()

        require("neo-tree").setup({
            enable_git_status = true,
            enable_diagnostics = true,
            follow_current_file = {
                enabled = true,
            },
            default_component_configs = {
                git_status = {
                    symbols = {
                        added = "✚",
                        deleted = "✖",
                        modified = "",
                        renamed = "➜",
                        untracked = "",
                        ignored = "◌",
                        unstaged = "",
                        staged = "✓",
                        conflict = "",
                    },
                    align = "right",
                },
            },
            window = {
                mappings = {
                    ["<space>"] = "none",
                },
            },
            git_status = {
                window = {
                    position = "float",
                    mappings = {
                        ["A"] = "git_add_all",
                        ["gu"] = "git_unstage_file",
                        ["ga"] = "git_add_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gP"] = "git_push",
                        ["gp"] = "git_pull",
                    },
                },
            },
            filesystem = {
                group_empty_dirs = true,
                scan_mode = "deep",
                use_libuv_file_watcher = true,
                filtered_items = {
                    hide_gitignored = false,
                    always_show = {
                        ".github",
                        ".scratch",
                    },
                    always_show_by_pattern = {
                        ".env*",
                        ".*ignore",
                    },
                    never_show = {
                        ".DS_Store",
                        "__pycache__",
                    },
                },
            },
        })
    end,
}
