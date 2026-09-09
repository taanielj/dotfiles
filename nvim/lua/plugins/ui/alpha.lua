return {
    "goolord/alpha-nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    config = function()
        local dashboard = require("alpha.themes.startify")
        dashboard.file_icons.provider = "devicons"
        dashboard.section.header.val = {
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                     ]],
            [[       ████ ██████           █████      ██                     ]],
            [[      ███████████             █████                             ]],
            [[      █████████ ███████████████████ ███   ███████████   ]],
            [[     █████████  ███    █████████████ █████ ██████████████   ]],
            [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
            [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
            [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
        }
        dashboard.section.top_buttons.val = {
            dashboard.button("e", " New file", ":ene <BAR> startinsert <CR>"),
        }
        dashboard.section.bottom_buttons.val = {
            dashboard.button("q", "󰅚 Quit NeoVim", ":qa<CR>"),
        }
        require("alpha").setup(dashboard.config)
    end,
}
