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

files=(
    setup/system.sh # only one that needs sudo, supports ubuntu, debian, termux, darwin
    setup/zsh.sh    # no sudo, platform agnostic
    setup/tmux.sh   # no sudo, platform agnostic
    setup/nvim.sh   # no sudo, platform agnostic
)

for file in files; do
    divider
    title "Running [$(basename "$file" .sh)] setup script"
    divider
    echo ""
    eval "main_$(basename "$file" .sh)"
done
