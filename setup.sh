#!/usr/bin/env bash

set -e
REPO_ROOT=$(git rev-parse --show-toplevel)

source "$REPO_ROOT/setup/utils.sh"

divider
title "Starting [taanielj/dotfiles] setup script"
divider
echo ""

# system should be run first

files=(
    "$REPO_ROOT/setup/system.sh" # only one that needs sudo, supports ubuntu, debian, termux, darwin
    "$REPO_ROOT/setup/zsh.sh"    # no sudo, platform agnostic
    "$REPO_ROOT/setup/tmux.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/mise.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/nvim.sh"   # no sudo, platform agnostic
)

for file in "${files[@]}"; do
    divider
    title "Running [$(basename "$file" .sh)] setup script"
    divider
    echo ""
    source "$file"
    eval "main_$(basename "$file" .sh)"
done

