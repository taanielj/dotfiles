#!/usr/bin/env bash

set -e
REPO_ROOT=$(git rev-parse --show-toplevel)

source "$REPO_ROOT/setup/utils.sh"

# system should be run first (and torn down last)
SETUP_SCRIPTS=(
    "$REPO_ROOT/setup/system.sh" # only one that needs sudo, supports ubuntu, debian, termux, darwin
    "$REPO_ROOT/setup/zsh.sh"    # no sudo, platform agnostic
    "$REPO_ROOT/setup/tmux.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/mise.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/nvim.sh"   # no sudo, platform agnostic
    "$REPO_ROOT/setup/cargo.sh"  # no sudo, platform agnostic
)
[[ "$OSTYPE" == "darwin"* ]] && SETUP_SCRIPTS+=("$REPO_ROOT/setup/kitty.sh" "$REPO_ROOT/setup/wezterm.sh")
[[ "$OSTYPE" == "linux-gnu"* ]] && SETUP_SCRIPTS+=("$REPO_ROOT/setup/lazygit.sh")

parse_args() {
    MODE="setup"
    remove_cargo=false

    for arg in "$@"; do
        case "$arg" in
        --teardown) MODE="teardown" ;;
        --remove-cargo) remove_cargo=true ;;
        esac
    done
}

show_banner() {
    divider
    if [[ "$MODE" == "teardown" ]]; then
        title "Starting [taanielj/dotfiles] tear-down"
    else
        title "Welcome to [taanielj/dotfiles] setup"
    fi
    divider
    echo ""

    if [[ "$MODE" == "setup" ]]; then
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
    fi
}

# Reverses SETUP_SCRIPTS, dropping system.sh (we don't want to remove system packages)
teardown_scripts() {
    local scripts=()
    for ((i=${#SETUP_SCRIPTS[@]}-1; i>=0; i--)); do
        [[ "$(basename "${SETUP_SCRIPTS[$i]}" .sh)" == "system" ]] && continue
        scripts+=("${SETUP_SCRIPTS[$i]}")
    done
    files=("${scripts[@]}")
}

select_scripts() {
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
        selected_files=("${SETUP_SCRIPTS[@]}")
        ;;
    "Custom")
        log "Select which setup scripts to run:"
        display_names=()
        for file in "${SETUP_SCRIPTS[@]}"; do
            display_names+=("$(basename "$file" .sh)")
        done

        selected_names=$(interactive_multi_choice "Select scripts: " "${display_names[@]}")

        if [[ -z "$selected_names" ]]; then
            warn "No scripts selected. Exiting."
            exit 0
        fi

        selected_files=()
        while IFS= read -r name; do
            for file in "${SETUP_SCRIPTS[@]}"; do
                [[ "$(basename "$file" .sh)" == "$name" ]] && selected_files+=("$file")
            done
        done <<<"$selected_names"
        ;;
    esac
}

run_setup() {
    for file in "${selected_files[@]}"; do
        divider
        title "Running [$(basename "$file" .sh)] setup script"
        divider
        echo ""
        source "$file"
        eval "main_$(basename "$file" .sh)"
    done
}

run_teardown() {
    for file in "${files[@]}"; do
        divider
        title "Running [$(basename "$file" .sh)] tear-down script"
        divider
        echo ""
        source "$file"

        case "$(basename "$file" .sh)" in
        cargo)
            teardown_cargo $([ "$remove_cargo" == true ] && echo "--remove-cargo")
            ;;
        *)
            eval "teardown_$(basename "$file" .sh)"
            ;;
        esac
    done
}

main() {
    parse_args "$@"
    show_banner

    if [[ "$MODE" == "teardown" ]]; then
        teardown_scripts
        run_teardown
    else
        select_scripts
        run_setup
    fi
}

main "$@"
