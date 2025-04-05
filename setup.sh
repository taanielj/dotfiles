#!/usr/bin/env bash

set -e
REPO_ROOT=$(git rev-parse --show-toplevel)

for file in "$REPO_ROOT"/setup/*.sh; do
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
    "$REPO_ROOT/setup/system.sh" # only one that needs sudo, supports ubuntu, debian, termux, darwin
    "$REPO_ROOT/setup/mise.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/zsh.sh"    # no sudo, platform agnostic
    "$REPO_ROOT/setup/tmux.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/nvim.sh"   # no sudo, platform agnostic
)

for file in "${files[@]}"; do
    divider
    title "Running [$(basename "$file" .sh)] setup script"
    divider
    echo ""
    eval "main_$(basename "$file" .sh)"
done

cargo_tools=(
    "eza"
    "zoxide"
)

[[ $(command -v cargo) ]] && {
    for tool in "${cargo_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            run_quiet "Installing $tool" cargo install "$tool"    
        fi
    done
}
