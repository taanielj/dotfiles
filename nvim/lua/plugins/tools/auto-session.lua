return {
    "rmagatti/auto-session",
    -- the session restore runs on VimEnter
    lazy = false,

    config = function()
        require("auto-session").setup({
            enabled = true,
            auto_save = true,
            auto_create = function()
                local cmd = "git rev-parse --is-inside-work-tree"
                return vim.fn.system(cmd) == "true\n"
            end,
            root_dir = vim.fn.stdpath("data") .. "/sessions/",
            close_unsupported_windows = true,
            suppressed_dirs = {
                "/tmp",
                "/private/tmp",
                "/var/tmp",
                "/usr/tmp",
                "/usr/local/tmp",
                "~/",
                "/",
                "~/git",
                "~/Downloads",
                "~/Desktop",
            },
            bypass_save_filetypes = {
                "snacks_dashboard",
                "neo-tree",
            },
            cwd_change_handling = true,
            pre_cwd_changed_cmds = {
                "tabdo Neotree action=close",
            },
            post_cwd_changed_cmds = {
                "tabdo Neotree show",
            },
            post_restore_cmds = {
                function()
                    local bufnr_list = vim.api.nvim_list_bufs()
                    local only_no_name = true
                    for _, bufnr in ipairs(bufnr_list) do
                        if vim.api.nvim_buf_get_name(bufnr) ~= "" then
                            only_no_name = false
                            break
                        end
                    end
                    if only_no_name then
                        vim.cmd("%bd!")
                        Snacks.dashboard()
                        vim.cmd("tabdo bd#")
                    else
                        vim.cmd("Neotree show")
                    end
                end,
            },
            pre_delete_cmds = {
                "Neotree action=close",
                "silent! wa",
                "silent! %bd!",
            },
            post_delete_cmds = {
                function()
                    return {
                        Snacks.dashboard(),
                        vim.cmd("bd#"),
                    }
                end,
            },
        })
    end,
}
