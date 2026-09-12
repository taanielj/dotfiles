local function conditional_breakpoint()
    vim.ui.input({ prompt = "Break when: " }, function(condition)
        if condition and condition ~= "" then
            require("dap").set_breakpoint(condition)
        end
    end)
end

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "igorlfs/nvim-dap-view",
        "leoluz/nvim-dap-go",
        -- Its rockspec makes lazy.nvim load it at startup unless marked lazy
        { "mfussenegger/nvim-dap-python", lazy = true },
        { "jay-babu/mason-nvim-dap.nvim", dependencies = { "mason-org/mason.nvim" } },
    },
    -- stylua: ignore
    keys = {
        { "<leader>dc", function() require("dap").continue() end,          desc = "Start or continue" },
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
        { "<leader>dB", conditional_breakpoint,                            desc = "Conditional breakpoint" },
        { "<leader>dt", function() require("lib.debug_test").run() end,    desc = "Debug test under cursor" },
        { "<leader>dl", function() require("dap").run_last() end,          desc = "Run last" },
        { "<leader>dv", function() require("dap-view").toggle() end,       desc = "Toggle debug view" },
        { "<leader>dw", function() require("dap-view").add_expr() end,     desc = "Watch expression" },
        { "<leader>dq", function() require("dap").terminate() end,         desc = "Terminate" },
        { "<leader>dd", function() require("ui.debug_mode").toggle() end,  desc = "Toggle debug mode keys" },
    },
    config = function()
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

        require("dap-view").setup({
            winbar = {
                default_section = "scopes",
                controls = { enabled = true },
            },
            -- The view closes with the session and keeps its terminal, to read the program's output
            auto_toggle = "keep_terminal",
            virtual_text = { enabled = true },
        })
        require("lib.herdr_debug_pane").setup()

        require("dap-go").setup()

        -- Without handlers mason-nvim-dap only installs; dap-python sets up the adapter
        require("mason-nvim-dap").setup({ ensure_installed = { "python" } })
        require("dap-python").setup(require("lib.mason").path("bin/debugpy-adapter"))

        local dap = require("dap")
        -- Exception filter names are the adapter's own; delve stops on panics by itself
        dap.defaults.python.exception_breakpoints = { "uncaught" }
        -- Every python session, whether a built-in config, launch.json or a test
        dap.listeners.on_config.python_return_value = function(config)
            if config.type ~= "python" then
                return config
            end
            return vim.tbl_extend("keep", config, { showReturnValue = true })
        end

        require("ui.debug_mode").setup()
    end,
}
