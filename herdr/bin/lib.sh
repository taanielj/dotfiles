# Sourced by the herdr key scripts in this directory.

herdr="${HERDR_BIN_PATH:-herdr}"

# Usage: runs_nvim <pane-id>
# Succeeds when Neovim is the pane's foreground process, the pattern herdr-splits uses.
runs_nvim() {
    [[ -n "$1" ]] &&
        "$herdr" pane process-info --pane "$1" 2>/dev/null |
        grep -qE '"name"\s*:\s*"(g?(view|l?n?vim?x?)(diff)?)"'
}

# Usage: hammerspoon <lua>
# Prints what Hammerspoon returns for the Lua. While Hammerspoon isn't running, `hs`
# hangs rather than fails; this fails instead and relaunches it in the background.
hammerspoon() {
    if ! pgrep -xq Hammerspoon; then
        open -g -a Hammerspoon
        return 1
    fi
    hs -c "$1" 2>/dev/null
}
