-- Returns the module for the multiplexer whose pane this nvim runs in, the
-- herdr TUI (lib/herdr.lua) or the Herdr app (lib/herdr_app.lua). Both modules
-- answer the same calls.
---@return (table|nil) nil outside both
return function()
    for _, name in ipairs({ "lib.herdr", "lib.herdr_app" }) do
        local host = require(name)
        if host.inside() then
            return host
        end
    end
    return nil
end
