return {
    "scalameta/nvim-metals",
    dependencies = {
        "j-hui/fidget.nvim",
        "mfussenegger/nvim-dap",
    },
    ft = { "scala", "sbt", "java" },
    opts = function()
        local metals_config = require("metals").bare_config()

        metals_config.settings = {
            showImplicitArguments = true,
            excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
        }

        -- "off" leaves the progress notifications to fidget.nvim
        metals_config.init_options.statusBarProvider = "off"

        metals_config.capabilities = require("lsp.capabilities").get()

        metals_config.on_attach = function(client, bufnr)
            require("metals").setup_dap()

            local map = require("lib.keymap").buffer(bufnr)

            map("n", "<leader>lc", vim.lsp.codelens.run, "Run code lens")
            map("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
            -- <leader>m (keybinds/editing.lua) already formats through the LSP

            map("n", "<leader>lo", function() require("metals").hover_worksheet() end, "Hover worksheet")
        end

        return metals_config
    end,
    config = function(self, metals_config)
        require("dap").configurations.scala = {
            {
                type = "scala",
                request = "launch",
                name = "RunOrTest",
                metals = {
                    runType = "runOrTestFile",
                },
            },
            {
                type = "scala",
                request = "launch",
                name = "Test Target",
                metals = {
                    runType = "testTarget",
                },
            },
        }

        local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = self.ft,
            callback = function()
                local root = vim.fs.root(0, require("lsp.scala").root_markers)
                if root then
                    require("metals").initialize_or_attach(metals_config)
                end
            end,
            group = nvim_metals_group,
        })
    end,
}
