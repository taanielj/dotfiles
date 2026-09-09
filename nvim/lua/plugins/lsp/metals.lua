return {
    {
        "scalameta/nvim-metals",
        dependencies = {
            {
                "j-hui/fidget.nvim",
                opts = {},
            },
            {
                "mfussenegger/nvim-dap",
                config = function()
                    local dap = require("dap")
                    local icons = require("lib.icons")

                    vim.fn.sign_define("DapBreakpoint", { text = icons.breakpoint .. " ", texthl = "DiagnosticError" })
                    vim.fn.sign_define(
                        "DapBreakpointCondition",
                        { text = icons.breakpoint_condition .. " ", texthl = "DiagnosticWarn" }
                    )
                    vim.fn.sign_define(
                        "DapBreakpointRejected",
                        { text = icons.breakpoint_rejected .. " ", texthl = "DiagnosticHint" }
                    )
                    vim.fn.sign_define(
                        "DapStopped",
                        { text = icons.stopped .. " ", texthl = "DiagnosticWarn", linehl = "CursorLine" }
                    )

                    dap.configurations.scala = {
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
                end,
            },
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

                map("n", "<leader>dc", function() require("dap").continue() end, "Continue")

                map("n", "<leader>dr", function() require("dap").repl.toggle() end, "Toggle REPL")

                map("n", "<leader>dK", function() require("dap.ui.widgets").hover() end, "Hover value")

                map("n", "<leader>dt", function() require("dap").toggle_breakpoint() end, "Toggle breakpoint")

                map("n", "<leader>dso", function() require("dap").step_over() end, "Step over")

                map("n", "<leader>dsi", function() require("dap").step_into() end, "Step into")

                map("n", "<leader>dl", function() require("dap").run_last() end, "Run last")
            end

            return metals_config
        end,
        config = function(self, metals_config)
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
    },
}
