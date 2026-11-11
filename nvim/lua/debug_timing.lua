-- Debug timing for the Herdr app key path: logs focus events and main loop
-- stalls to ~/.config/herdr-app/keys-timing-nvim.log, next to the keys mod's
-- keys-timing.log. Load with :lua require("debug_timing")
local PATH = vim.env.HOME .. "/.config/herdr-app/keys-timing-nvim.log"
local TICK_MS = 50
local STALL_MS = 200

local function now_ms()
    local sec, usec = vim.uv.gettimeofday()
    return sec * 1000 + math.floor(usec / 1000)
end

local function log(label, at)
    local file = io.open(PATH, "a")
    if file then
        file:write(("%d nvim %s %s\n"):format(at or now_ms(), vim.env.HC_TERMINAL_ID or "-", label))
        file:close()
    end
end

-- A timer callback runs on the main loop. A late tick means the loop was blocked.
local last = now_ms()
local function tick()
    local t = now_ms()
    if t - last > STALL_MS then
        log(("blocked %dms"):format(t - last - TICK_MS), last)
    end
    last = t
end

-- A second load replaces the first one's timer
if _G.debug_timing_timer then
    _G.debug_timing_timer:close()
end
_G.debug_timing_timer = vim.uv.new_timer()

vim.api.nvim_create_autocmd({ "FocusGained", "FocusLost" }, {
    group = vim.api.nvim_create_augroup("debug_timing", { clear = true }),
    callback = function(args) log(args.event) end,
})

_G.debug_timing_timer:start(TICK_MS, TICK_MS, tick)

log("debug_timing loaded")
