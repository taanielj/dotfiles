#!/usr/bin/env bash
# Claude Code's EDITOR, linked onto PATH as herdr-nvim. Its prompt (ctrl+g) and
# transcript (ctrl+o v) open in the nvim running in the same herdr tab
# (nvim/lua/ui/claude_editor.lua); without one, this is plain nvim.
set -euo pipefail

# Claude puts the file last, after +<line> for an editor it knows
file="${*: -1}"

server=""
if [[ -n "${HERDR_TAB_ID:-}" ]]; then
    for socket in "${TMPDIR:-/tmp}"/nvim."$USER"/*/nvim.*.0; do
        # shellcheck disable=SC2016 # nvim's $HERDR_TAB_ID, not this shell's
        tab=$(nvim --clean --headless --server "$socket" --remote-expr '$HERDR_TAB_ID' 2>/dev/null) || continue
        if [[ "$tab" == "$HERDR_TAB_ID" ]]; then
            server=$socket
            break
        fi
    done
fi
[[ -n "$server" ]] || exec nvim "$@"

# Usage: call <function> <args as a vimscript list>
# Prints 1 once the tab's nvim has taken the file.
call() {
    nvim --clean --headless --server "$server" --remote-expr \
        "luaeval('require(\"ui.claude_editor\").$1(unpack(_A))', $2)" 2>/dev/null
}

case "$file" in
*/cc-transcript-*.txt)
    [[ "$(call view "['$file']")" == 1 ]] || exec nvim "$@"
    exit
    ;;
esac

done_fifo=$(mktemp -u "${TMPDIR:-/tmp}/herdr-nvim.XXXXXX")
mkfifo "$done_fifo"
trap 'rm -f "$done_fifo"' EXIT

nvim_pid=$(nvim --clean --headless --server "$server" --remote-expr 'getpid()')
if [[ "$(call edit "['$file', '$done_fifo', '$HERDR_PANE_ID']")" != 1 ]]; then
    rm -f "$done_fifo"
    exec nvim "$@"
fi
# Claude has cleared its screen and redraws once this exits
printf '\033[2J\033[H\n  Editing in nvim: ZZ hands back, ZQ cancels, <C-s> submits\n' >/dev/tty

# nvim writes the fifo when the edit ends; an nvim that died without doing so
# has the watcher write it instead
(
    while kill -0 "$nvim_pid" 2>/dev/null; do sleep 1; done
    echo >"$done_fifo"
) &
read -r _ <"$done_fifo"
kill $! 2>/dev/null || true
