#!/usr/bin/env bash
# CPU/RAM for the herdr tab bar. macOS and Linux.
# ps %cpu is since-process-start, so this is an approximation, not a live sample.
set -euo pipefail

ncpu=$(getconf _NPROCESSORS_ONLN)
cpu=$(ps -A -o %cpu= | awk -v n="$ncpu" '{s+=$1} END {printf "%.0f", s/n}')

if [[ -r /proc/meminfo ]]; then
    read -r used_gb total_gb < <(awk '
        /^MemTotal:/     { t=$2 }
        /^MemAvailable:/ { a=$2 }
        END { printf "%.0f %.0f\n", (t-a)/1048576, t/1048576 }' /proc/meminfo)
else
    total_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
    used_gb=$(vm_stat | awk '
        /page size of/           { ps=$8 }
        /Pages active/           { a=$3 }
        /Pages wired/            { w=$4 }
        /occupied by compressor/ { c=$5 }
        END {
            gsub(/\./, "", a); gsub(/\./, "", w); gsub(/\./, "", c)
            printf "%.0f", (a + w + c) * ps / 1073741824
        }')
fi

printf " %3s%%   %2s/%sG" "$cpu" "$used_gb" "$total_gb"
