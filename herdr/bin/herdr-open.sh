#!/usr/bin/env bash
# Usage: herdr-open <terminal> <file>
# Opens the file in the nvim running in that Herdr app terminal. Fails when no
# nvim there serves a socket.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"

terminal="${1:?usage: herdr-open <terminal> <file>}"
file="${2:?usage: herdr-open <terminal> <file>}"

while read -r socket; do
    if [[ "$(nvim_env "$socket" HC_TERMINAL_ID)" == "$terminal" ]]; then
        [[ "$(nvim --clean --headless --server "$socket" --remote-expr \
            "luaeval('require(\"ui.open_file\").open(_A)', '${file//\'/\'\'}')" 2>/dev/null)" == 1 ]]
        exit
    fi
done < <(nvim_servers)
exit 1
