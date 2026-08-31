#!/usr/bin/env bash
# CPU/RAM summary for the herdr tab bar (ui.tab_bar_right command entry).
# macOS only: vm_stat/sysctl. ps %cpu is per-process since-start, summed and
# normalized by core count — cheap, close enough for a glanceable meter.
set -euo pipefail

ncpu=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu= | awk -v n="$ncpu" '{s+=$1} END {printf "%.0f", s/n}')

total_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
used_gb=$(vm_stat | awk '
    /page size of/               { ps=$8 }
    /Pages active/               { a=$3 }
    /Pages wired/                { w=$4 }
    /occupied by compressor/     { c=$5 }
    END {
        gsub(/\./, "", a); gsub(/\./, "", w); gsub(/\./, "", c)
        printf "%.0f", (a + w + c) * ps / 1073741824
    }')

# Right-aligned fixed widths so the segment doesn't shift as values change
printf " %3s%%   %2s/%sG" "$cpu" "$used_gb" "$total_gb"
