return {
    "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "python", "java" },
    config = function()
        require("sonarlint").setup({
            server = {
                cmd = {
                    vim.fn.stdpath("data") .. "/mason/bin/sonarlint-language-server",
                    "-stdio",
                    "-analyzers",
                    vim.fn.stdpath("data") .. "/mason/share/sonarlint-analyzers/sonarpython.jar",
                    vim.fn.stdpath("data") .. "/mason/share/sonarlint-analyzers/sonarjava.jar",
                },
                settings = {
                    sonarlint = (function()
                        -- Connected mode needs both; set them in ~/.zshrc.local per machine.
                        local token = os.getenv("SONAR_TOKEN")
                        local server_url = os.getenv("SONAR_HOST_URL")
                        if not token or not server_url then return {} end
                        local props = vim.fn.getcwd() .. "/sonar-project.properties"
                        local project_key = nil
                        local f = io.open(props, "r")
                        if f then
                            for line in f:lines() do
                                project_key = line:match("^sonar%.projectKey=(.+)")
                                if project_key then break end
                            end
                            f:close()
                        end
                        if not project_key then return {} end
                        return {
                            connectedMode = {
                                connections = {
                                    sonarqube = {
                                        {
                                            connectionId = "default",
                                            serverUrl = server_url,
                                            token = token,
                                        },
                                    },
                                },
                                project = {
                                    connectionId = "default",
                                    projectKey = project_key,
                                },
                            },
                        }
                    end)(),
                },
            },
            filetypes = { "python", "java" },
        })
    end,
}
