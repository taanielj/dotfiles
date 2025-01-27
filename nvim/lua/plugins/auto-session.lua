return {
	"rmagatti/auto-session",
	lazy = false,

	config = function()
		require("auto-session").setup({
			atuo_restore_last_session = true,
			auto_save_enabled = true,
			auto_create = function()
				local cmd = "git rev-parse --is-inside-work-tree"
				return vim.fn.system(cmd) == "true\n"
			end,
			auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
			auto_session_enabled_filetypes = {
				"dashboard",
				"alpha",
			},
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
			bypass_save_filetype = {
				"dashboard",
				"alpha",
			},
			cwd_change_handling = true,
			pre_cwd_changed_cmds = {
				"tabdo Neotree action=close",
			},
            post_cwd_changed_cmds = {
                "tabdo Neotree",
            },
            post_restore_cmds = {
                "tabdo Neotree",
            },
		})
	end,
}
