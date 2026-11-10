#!/usr/bin/env bash
# Weather from wttr.in for the herdr tab bar and the Herdr app's status bar.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-weather"
mkdir -p "$(dirname "$cache")"
# Cached here, because a config reload reruns every tab bar command
max_age=900

# Try GNU stat first. GNU stat reads "-f %m" as a filename and prints the error
# on stdout, while BSD stat rejects "-c" on stderr.
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

if [[ -s $cache ]]; then
    age=$(( $(date +%s) - $(mtime "$cache") ))
    if (( age < max_age )); then
        cat "$cache"
        exit 0
    fi
fi

if out=$(curl -sf -m 5 'https://wttr.in/?format=%c|%t' 2>/dev/null) && [[ $out == *"|"* ]]; then
    temp=${out##*|}
    # printf pads by bytes. Only the ASCII digits can be padded, because the emoji
    # and °C are multibyte and would jitter
    printf '%s%4s°C' "${out%%|*}" "${temp%°C}" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
