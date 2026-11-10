#!/usr/bin/env bash
# herdr's edit_scrollback, skipped when the pane has nothing to scroll back
# to: a full-screen app such as nvim, or an agent that redraws its view. The
# editor is a socket method with no CLI subcommand, hence the request below.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_ACTIVE_PANE_ID:?}"

offset=$("$herdr" pane get "$pane" | jq '.result.pane.scroll.max_offset_from_bottom')
[[ "$offset" -gt 0 ]] || exit 0

printf '{"id":"scrollback","method":"pane.edit_scrollback","params":{"pane_id":"%s"}}\n' "$pane" |
    python3 -c '
import os, socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect(os.environ["HERDR_SOCKET_PATH"])
s.sendall(sys.stdin.buffer.read())
s.recv(4096)
'
