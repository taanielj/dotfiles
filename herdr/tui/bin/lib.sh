# Sourced by the herdr key scripts in this directory.

herdr="${HERDR_BIN_PATH:-herdr}"

# Usage: runs_nvim <pane-id>
# Succeeds when Neovim is the pane's foreground process. The name regex is
# copied from herdr-splits.
runs_nvim() {
    [[ -n "$1" ]] &&
        "$herdr" pane process-info --pane "$1" 2>/dev/null |
        grep -qE '"name"\s*:\s*"(g?(view|l?n?vim?x?)(diff)?)"'
}

# Usage: hammerspoon <lua>
# Prints what Hammerspoon returns for the Lua.
hammerspoon() {
    command -v hs >/dev/null || return 1
    # `hs` hangs while Hammerspoon isn't running
    if ! pgrep -xq Hammerspoon; then
        open -g -a Hammerspoon
        return 1
    fi
    hs -c "$1" 2>/dev/null
}
