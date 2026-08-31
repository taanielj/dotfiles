#!/usr/bin/env bash
# Weather for the herdr tab bar via wttr.in (the same source tmux-weather
# wraps). The cache is authoritative for 30 minutes no matter how often the
# script runs (config reloads re-run command entries immediately); wttr.in is
# only hit once it expires, and a failed fetch keeps the previous reading.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-weather"
mkdir -p "$(dirname "$cache")"
max_age=1800

if [[ -s $cache ]]; then
    age=$(( $(date +%s) - $(stat -f %m "$cache") ))
    if (( age < max_age )); then
        cat "$cache"
        exit 0
    fi
fi

if out=$(curl -sf -m 5 'https://wttr.in/?format=%c%t' 2>/dev/null) && [[ -n $out ]]; then
    printf '%s' "$out" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
