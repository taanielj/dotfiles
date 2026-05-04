return {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    opts = function()
        local jdtls_path = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
        local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspaces/" .. project_name

        return {
            cmd = { jdtls_path, "-data", workspace_dir },
            root_dir = vim.fs.root(0, { "mvnw", "pom.xml", "gradlew", "build.gradle", ".git" }),
            settings = {
                java = {
                    signatureHelp = { enabled = true },
                    completion = {
                        favoriteStaticMembers = {
                            "org.assertj.core.api.Assertions.*",
                            "org.mockito.Mockito.*",
                            "org.mockito.ArgumentMatchers.*",
                        },
                    },
                    sources = {
                        organizeImports = {
                            starThreshold = 9999,
                            staticStarThreshold = 9999,
                        },
                    },
                },
            },
        }
    end,
    config = function(_, opts)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = function()
                -- Skip if this is a Scala project (metals handles Java there)
                if vim.fs.root(0, { "build.sbt", "build.sc", ".scala-build" }) then
                    return
                end
                require("jdtls").start_or_attach(opts)
            end,
            group = vim.api.nvim_create_augroup("nvim-jdtls", { clear = true }),
        })
    end,
}
