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
                        local token = os.getenv("SONAR_TOKEN")
                        if not token then return {} end
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
                                            connectionId = "zendesk",
                                            serverUrl = "https://sonarqube.staging-zende.sk",
                                            token = token,
                                        },
                                    },
                                },
                                project = {
                                    connectionId = "zendesk",
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
