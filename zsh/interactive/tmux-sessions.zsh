# TMUX sessions. Extra sessions can register via register_tmux_session
# (e.g. from ~/.zshrc.local).
: "${GIT_PATH:=$HOME/git}"

typeset -ga default_sessions=()
typeset -gA _tmux_session_builders=()

register_tmux_session() {
    default_sessions+=("$1")
    _tmux_session_builders[$1]="$2"
}

# Helper: Create tmux session with optional directory
_tmux_new_session_maybe_dir() {
    local session="$1"
    local window_name="$2"
    local dir="$3"

    if [[ -n "$dir" && -d "$dir" ]]; then
        tmux new-session -d -s "$session" -n "$window_name" -c "$dir"
    else
        tmux new-session -d -s "$session" -n "$window_name"
    fi
}

# Helper: Create tmux window with optional directory
_tmux_new_window_maybe_dir() {
    local session="$1"
    local window_name="$2"
    local dir="$3"

    # Trailing colon forces a session target, even when a window shares the name.
    if [[ -n "$dir" && -d "$dir" ]]; then
        tmux new-window -t "${session}:" -n "$window_name" -c "$dir"
    else
        tmux new-window -t "${session}:" -n "$window_name"
    fi
}

_tmux_build_shell() {
    tmux new-session -d -s shell
}
register_tmux_session shell _tmux_build_shell

_start_all_sessions() {
    local session builder
    for session in "${default_sessions[@]}"; do
        tmux has-session -t "$session" 2>/dev/null && continue
        builder="${_tmux_session_builders[$session]}"
        [[ -n "$builder" ]] && "$builder"
    done
}

# Main entry: attach to first unattached session
ts() {
    _start_all_sessions

    for session in "${default_sessions[@]}"; do
        if ! tmux list-clients -t "$session" 2>/dev/null | grep -q '^'; then
            tmux attach-session -t "$session"
            return
        fi
    done

    echo "You have shells attached to all sessions."
    return 1
}

# Attach helpers
tss() {
    _start_all_sessions
    tmux attach-session -t shell
}
