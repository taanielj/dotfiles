#!/usr/bin/env bash

set -e
REPO_ROOT=$(git rev-parse --show-toplevel)

source "$REPO_ROOT/setup/utils.sh"

divider
title "Welcome to [taanielj/dotfiles] setup"
divider
echo ""

# Detect OS for display
OS_NAME="Unknown"
case "$OSTYPE" in
darwin*) OS_NAME="macOS" ;;
linux-gnu*) OS_NAME="Linux" ;;
linux-android*) OS_NAME="Termux/Android" ;;
esac

log "Detected platform: $OS_NAME"
echo ""
log "This setup will install and configure:"
log "  • System packages (git, zsh, tmux, fzf, etc.)"
log "  • Shell configuration (zsh with custom config)"
log "  • Terminal multiplexer (tmux with plugins)"
log "  • Version manager (mise with language runtimes)"
log "  • Text editor (neovim with plugins)"
log "  • Rust tools (cargo packages like eza, ripgrep, bat)"
[[ "$OSTYPE" == "darwin"* ]] && log "  • Terminal emulators (kitty, wezterm)"
[[ "$OSTYPE" == "linux-gnu"* ]] && log "  • Git TUI (lazygit)"
echo ""

# system should be run first
files=(
    "$REPO_ROOT/setup/system.sh" # only one that needs sudo, supports ubuntu, debian, termux, darwin
    "$REPO_ROOT/setup/zsh.sh"    # no sudo, platform agnostic
    "$REPO_ROOT/setup/tmux.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/mise.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/nvim.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/cargo.sh"  # no sudo, platform agnostic
)
[[ "$OSTYPE" == "darwin"* ]] && files+=("$REPO_ROOT/setup/kitty.sh" "$REPO_ROOT/setup/wezterm.sh")
[[ "$OSTYPE" == "linux-gnu"* ]] && files+=("$REPO_ROOT/setup/lazygit.sh")

# Ask user what they want to do
log "Choose setup mode:"
mode=$(interactive_choice "Mode: " "System only" "All" "Custom" "Exit")

case "$mode" in
"Exit")
    log "Exiting setup."
    exit 0
    ;;
"System only")
    log "Running system setup only..."
    selected_files=("$REPO_ROOT/setup/system.sh")
    ;;
"All")
    log "Running all setup scripts..."
    selected_files=("${files[@]}")
    ;;
"Custom")
    log "Select which setup scripts to run:"
    # Create display names without path and extension
    display_names=()
    for file in "${files[@]}"; do
        display_names+=("$(basename "$file" .sh)")
    done

    selected_names=$(interactive_multi_choice "Select scripts: " "${display_names[@]}")

    if [[ -z "$selected_names" ]]; then
        warn "No scripts selected. Exiting."
        exit 0
    fi

    # Map selected names back to file paths
    selected_files=()
    while IFS= read -r name; do
        for file in "${files[@]}"; do
            [[ "$(basename "$file" .sh)" == "$name" ]] && selected_files+=("$file")
        done
    done <<<"$selected_names"
    ;;
esac

# Run selected scripts
for file in "${selected_files[@]}"; do
    divider
    title "Running [$(basename "$file" .sh)] setup script"
    divider
    echo ""
    source "$file"
    eval "main_$(basename "$file" .sh)"
done
