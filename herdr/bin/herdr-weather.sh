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

# printf pads by bytes, so only the ASCII part gets padded: emoji and °C are
# multibyte and would jitter. Temp is split out, stripped to sign+digits,
# padded to 4 columns ("+5" .. "-12" .. "+30"), and cached padded.
if out=$(curl -sf -m 5 'https://wttr.in/?format=%c|%t' 2>/dev/null) && [[ $out == *"|"* ]]; then
    temp=${out##*|}
    printf '%s%4s°C' "${out%%|*}" "${temp%°C}" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
