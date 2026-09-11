local mason = require("lib.mason")

---@param root_dir string
---@return string?
local function project_key(root_dir)
    local f = io.open(vim.fs.joinpath(root_dir, "sonar-project.properties"), "r")
    if not f then
        return nil
    end
    local key
    for line in f:lines() do
        key = line:match("^sonar%.projectKey=(.+)")
        if key then
            break
        end
    end
    f:close()
    return key
end

---@param root_dir string
local function connected_mode(root_dir)
    -- Connected mode needs both; set them in ~/.zshrc.local per machine.
    local token = os.getenv("SONAR_TOKEN")
    local server_url = os.getenv("SONAR_HOST_URL")
    local key = token and server_url and project_key(root_dir)
    if not key then
        return nil
    end
    return {
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
            projectKey = key,
        },
    }
end

return {
    "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "python", "java" },
    config = function()
        require("sonarlint").setup({
            server = {
                cmd = {
                    mason.path("bin/sonarlint-language-server"),
                    "-stdio",
                    "-analyzers",
                    mason.path("share/sonarlint-analyzers/sonarpython.jar"),
                    mason.path("share/sonarlint-analyzers/sonarjava.jar"),
                },
                -- sonarlint.nvim replaces on_init; config.settings is the client's own table
                before_init = function(_, config)
                    config.settings.sonarlint.connectedMode = connected_mode(config.root_dir)
                end,
            },
            filetypes = { "python", "java" },
        })
    end,
}
