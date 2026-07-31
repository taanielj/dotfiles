#!/usr/bin/env bash
# Dump the calling pane's scrollback into nvim for real search/yank/copy.
# Herdr-native take on tmux's capture-pane -> editor.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
tmp="$(mktemp -t herdr-scrollback.XXXXXX)"
trap 'rm -f "$tmp"' EXIT

"$herdr" pane read "${HERDR_ACTIVE_PANE_ID}" --source recent --lines 10000 --format text >"$tmp"
nvim "+normal G" "$tmp"
