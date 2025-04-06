#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

TOOLS=(
    "eza"
    "zoxide"
    "bat"
    "ripgrep"
    "fd"
)

main_cargo() {
    install_cargo_tools
}

install_cargo_tools() {
    # Ensure ~/.cargo/bin is in PATH
    case ":$PATH:" in
        *":$HOME/.cargo/bin:"*) ;;
        *) export PATH="$HOME/.cargo/bin:$PATH" ;;
    esac

    if ! command -v cargo &>/dev/null; then
        error "❌ Cargo is not installed. Please install it first."
        return 1
    fi

    log "Installing cargo tools..."
    for tool in "${TOOLS[@]}"; do
        run_quiet "📦 Installing $tool" cargo install "$tool"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_cargo "$@"
fi

