return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		vim.o.timeoutlen = 200
		local wk = require("which-key")
		wk.register({
			f = {
				name = "+Find",
				h = {
					name = "+Hidden",
				},
			},
			g = {
				name = "+Git",
			},

            b = {
                name = "+Buffer",
                {
                    s = "+Sort",
                },
                {
                    m = "+Move",
                },
            },
            l = {
                name = "+LSP"
            },
		}, { prefix = "<leader>" })

		require("which-key").setup()
	end,
}
