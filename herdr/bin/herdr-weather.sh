#!/usr/bin/env bash
# Weather from wttr.in for the herdr tab bar and the Herdr app's status bar. The
# script caches for 15 minutes itself, because a config reload reruns every tab
# bar command.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-weather"
mkdir -p "$(dirname "$cache")"
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

# printf pads by bytes, so only the ASCII digits can be padded; the emoji and
# °C are multibyte and would jitter
if out=$(curl -sf -m 5 'https://wttr.in/?format=%c|%t' 2>/dev/null) && [[ $out == *"|"* ]]; then
    temp=${out##*|}
    printf '%s%4s°C' "${out%%|*}" "${temp%°C}" > "$cache"
fi
[[ -f $cache ]] && cat "$cache"
