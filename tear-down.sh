#!/usr/bin/env bash

set -e
REPO_ROOT=$(git rev-parse --show-toplevel)

source "$REPO_ROOT/setup/utils.sh"

# Parse command line options
remove_cargo=false

for arg in "$@"; do
    case "$arg" in
    --remove-cargo) remove_cargo=true ;;
    esac
done

divider
title "Starting [taanielj/dotfiles] tear-down script"
divider
echo ""

# Define the files in reverse order as setup.sh
files=()

# Add platform-specific files
[[ "$OSTYPE" == "darwin"* ]] && files+=("$REPO_ROOT/setup/kitty.sh")
[[ "$OSTYPE" == "linux-gnu"* ]] && files+=("$REPO_ROOT/setup/lazygit.sh")

# Add common files in reverse order of setup.sh
files+=(
    "$REPO_ROOT/setup/cargo.sh"
    "$REPO_ROOT/setup/nvim.sh"
    "$REPO_ROOT/setup/mise.sh"
    "$REPO_ROOT/setup/tmux.sh"
    "$REPO_ROOT/setup/zsh.sh"
    # system.sh is omitted as we don't want to remove system packages
)

for file in "${files[@]}"; do
    divider
    title "Running [$(basename "$file" .sh)] tear-down script"
    divider
    echo ""
    source "$file"

    # Pass appropriate arguments to each teardown function
    case "$(basename "$file" .sh)" in
    cargo)
        teardown_cargo $([ "$remove_cargo" == true ] && echo "--remove-cargo")
        ;;
    *)
        eval "teardown_$(basename "$file" .sh)"
        ;;
    esac
done
