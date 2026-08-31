#!/usr/bin/env bash
# Up/down speed on the default-route interface, for the herdr tab bar.
# macOS and Linux.
set -euo pipefail

if [[ -d /sys/class/net ]]; then
    iface=$({ ip route show default 2>/dev/null || true; } |
        awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
    [[ -n "${iface:-}" ]] || { printf "󰖪 offline"; exit 0; }
    rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
    tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
else
    iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
    [[ -n "${iface:-}" ]] || { printf "󰖪 offline"; exit 0; }
    read -r rx tx < <(netstat -ibn -I "$iface" | awk 'NR==2 {print $7, $10}')
fi
now=$(date +%s)

state="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-netspeed"
mkdir -p "$(dirname "$state")"
prev_now=0 prev_rx=$rx prev_tx=$tx
[[ -f $state ]] && read -r prev_now prev_rx prev_tx < "$state"
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state"

elapsed=$(( now - prev_now ))
rx_rate=0 tx_rate=0
# a stale sample or a counter reset (reboot, interface switch) would fake a spike
if (( elapsed > 0 && elapsed <= 60 && rx >= prev_rx && tx >= prev_tx )); then
    rx_rate=$(( (rx - prev_rx) / elapsed ))
    tx_rate=$(( (tx - prev_tx) / elapsed ))
fi

human() {
    awk -v b="$1" 'BEGIN {
        split("B K M G", u, " ")
        i = 1
        while (b >= 1024 && i < 4) { b /= 1024; i++ }
        printf ((i >= 3 && b < 10) ? "%.1f%s" : "%.0f%s"), b, u[i]
    }'
}

# %5s fits the widest human() output ("1023M")
printf " %5s/s  %5s/s" "$(human "$rx_rate")" "$(human "$tx_rate")"
