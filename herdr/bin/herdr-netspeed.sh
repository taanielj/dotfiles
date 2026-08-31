#!/usr/bin/env bash
# Up/down speed for the herdr tab bar. netstat counters are cumulative, so
# each run diffs against the previous sample stored in a cache file; the
# first run (or a counter reset / interface switch) shows 0.
set -euo pipefail

iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
[[ -n "${iface:-}" ]] || { printf "󰖪 offline"; exit 0; }

read -r rx tx < <(netstat -ibn -I "$iface" | awk 'NR==2 {print $7, $10}')
now=$(date +%s)

state="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-netspeed"
mkdir -p "$(dirname "$state")"
prev_now=0 prev_rx=$rx prev_tx=$tx
[[ -f $state ]] && read -r prev_now prev_rx prev_tx < "$state"
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state"

elapsed=$(( now - prev_now ))
rx_rate=0 tx_rate=0
if (( elapsed > 0 && elapsed <= 60 && rx >= prev_rx && tx >= prev_tx )); then
    rx_rate=$(( (rx - prev_rx) / elapsed ))
    tx_rate=$(( (tx - prev_tx) / elapsed ))
fi

human() {
    awk -v b="$1" 'BEGIN {
        split("B K M G", u, " ")
        i = 1
        while (b >= 1024 && i < 4) { b /= 1024; i++ }
        printf (i >= 3 ? "%.1f%s" : "%.0f%s"), b, u[i]
    }'
}

printf " %s/s  %s/s" "$(human "$rx_rate")" "$(human "$tx_rate")"
