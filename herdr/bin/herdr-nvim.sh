#!/usr/bin/env bash
# Claude Code's EDITOR, linked onto PATH as herdr-nvim. Its prompt (ctrl+g) and
# transcript (ctrl+o v) open in the nvim running in the same herdr or Herdr app
# tab (nvim/lua/ui/claude_editor.lua); without one, this is plain nvim.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"

# Claude puts the file last, after +<line> for an editor it knows
file="${*: -1}"

# Usage: app_tab <terminal>
# Prints the Herdr app tab showing the terminal.
app_tab() {
    jq -r --arg t "$1" '.spaces[].tabs[] | select(any(.terminals[]; .terminal == $t)) | .id' <<<"$app_ls"
}

server=""
if [[ -n "${HERDR_TAB_ID:-}" ]]; then
    pane="$HERDR_PANE_ID"
    while read -r socket; do
        if [[ "$(nvim_env "$socket" HERDR_TAB_ID)" == "$HERDR_TAB_ID" ]]; then
            server=$socket
            break
        fi
    done < <(nvim_servers)
elif [[ -n "${HC_TERMINAL_ID:-}" ]] && app_ls=$(herdr-app ls 2>/dev/null); then
    pane="$HC_TERMINAL_ID"
    tab=$(app_tab "$HC_TERMINAL_ID")
    while read -r socket; do
        terminal=$(nvim_env "$socket" HC_TERMINAL_ID) || continue
        if [[ -n "$terminal" && "$(app_tab "$terminal")" == "$tab" ]]; then
            server=$socket
            break
        fi
    done < <(nvim_servers)
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
if [[ "$(call edit "['$file', '$done_fifo', '$pane']")" != 1 ]]; then
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
