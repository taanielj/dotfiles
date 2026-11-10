#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

TOOLS=(
    "eza"
    "zoxide"
    "bat"
    "git-delta" # lazygit diff renderer
    "ripgrep"
    "fd-find"
)

main_cargo() {
    install_cargo_tools
}

# A cargo installed earlier in this run isn't on this shell's PATH yet.
ensure_cargo_on_path() {
    case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) export PATH="$HOME/.cargo/bin:$PATH" ;;
    esac
}

install_cargo_tools() {
    ensure_cargo_on_path

    if ! command -v cargo &>/dev/null; then
        error "❌ Cargo is not installed. Please install it first."
        return 1
    fi

    log "Installing cargo tools..."
    # --locked builds with each tool's own lockfile; newest deps can break the build
    for tool in "${TOOLS[@]}"; do
        run_quiet "📦 Installing $tool" cargo install --locked "$tool"
    done
}

teardown_cargo() {
    local remove_cargo=false

    for arg in "$@"; do
        case "$arg" in
        --remove-cargo) remove_cargo=true ;;
        esac
    done

    ensure_cargo_on_path

    if ! command -v cargo &>/dev/null; then
        warn "Cargo is not installed. Nothing to uninstall."
        return 0
    fi

    log "Uninstalling cargo tools..."
    for tool in "${TOOLS[@]}"; do
        if cargo install --list | grep -q "^$tool "; then
            log "Uninstalling $tool"
            cargo uninstall "$tool" 2>/dev/null || true
        else
            log "$tool is not installed, skipping"
        fi
    done

    if [[ "$remove_cargo" == true ]]; then
        if command -v rustup &>/dev/null; then
            log "Removing rustup installation"
            rustup self uninstall -y
        fi

        if [[ -d "$HOME/.cargo" ]]; then
            log "Removing cargo installation directory"
            rm -rf "$HOME/.cargo"
        fi

        rc_remove_lines_containing ".cargo/bin"

        log "Cargo has been completely removed"
    fi

    success "Cargo tools uninstalled."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_cargo "$@"
fi
