#!/usr/bin/env bash
# Weather for the herdr tab bar via wttr.in (the same source tmux-weather
# wraps). Last good response is cached so a failed fetch keeps the previous
# reading instead of blanking the segment.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-weather"
mkdir -p "$(dirname "$cache")"

if out=$(curl -sf -m 5 'https://wttr.in/?format=%c%t' 2>/dev/null) && [[ -n $out ]]; then
    printf '%s' "$out" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
