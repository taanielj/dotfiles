#!/usr/bin/env bash

set -e

for file in setup/*.sh; do
    source "$file"
done

divider
title "Starting [taanielj/dotfiles] setup script"
divider
echo ""

# system should be run first

divider
title "Running [system] setup script"
divider
echo ""

main_system


for file in setup/*.sh; do
    if [[ "$file" == "setup/system.sh" || "$file" == "setup/utils.sh" ]]; then
        continue
    fi
    divider
    title "Running [$(basename "$file" .sh)] setup script"
    divider
    echo ""
    eval "main_$(basename "$file" .sh)"
done
