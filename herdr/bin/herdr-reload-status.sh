#!/usr/bin/env bash
# Tab bar entry: the last config reload result, until it expires.
file="${XDG_STATE_HOME:-$HOME/.local/state}/herdr/reload-result"
[[ -r "$file" ]] || exit 0
read -r expires message <"$file"
[[ "$(date +%s)" -lt "$expires" ]] && printf '%s' "$message"
exit 0
