#!/usr/bin/env bash
# Weather for the herdr tab bar via wttr.in. The 30m gate lives here rather
# than in interval_seconds because config reloads re-run command entries.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-weather"
mkdir -p "$(dirname "$cache")"
max_age=1800

mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"; }

if [[ -s $cache ]]; then
    age=$(( $(date +%s) - $(mtime "$cache") ))
    if (( age < max_age )); then
        cat "$cache"
        exit 0
    fi
fi

# printf pads by bytes, so only the ASCII digits can be padded; the emoji and
# °C are multibyte and would jitter
if out=$(curl -sf -m 5 'https://wttr.in/?format=%c|%t' 2>/dev/null) && [[ $out == *"|"* ]]; then
    temp=${out##*|}
    printf '%s%4s°C' "${out%%|*}" "${temp%°C}" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
