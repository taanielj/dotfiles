#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

TOOLS=(
    "eza"
    "zoxide"
    "bat"
    "ripgrep"
    "fd-find"
)

main_cargo() {
    install_cargo_tools
}

install_cargo_tools() {
    # PATH check needed because cargo may be installed but not yet in this shell's PATH
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

teardown_cargo() {
    local remove_cargo=false

    for arg in "$@"; do
        case "$arg" in
        --remove-cargo) remove_cargo=true ;;
        esac
    done

    case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) export PATH="$HOME/.cargo/bin:$PATH" ;;
    esac

    if ! command -v cargo &>/dev/null; then
        warn "Cargo is not installed. Nothing to uninstall."
        return 0
    fi

    log "Uninstalling cargo tools..."
    for tool in "${TOOLS[@]}"; do
        if cargo install --list | grep -q "^$tool "; then
            log "Uninstalling $tool"
            # The || true ensures the script continues even if uninstallation fails
            cargo uninstall "$tool" 2>/dev/null || true
        else
            log "$tool is not installed, skipping"
        fi
    done

    if [[ "$remove_cargo" == true ]]; then
        if [[ -d "$HOME/.cargo" ]]; then
            log "Removing cargo installation directory"
            rm -rf "$HOME/.cargo"
        fi

        if command -v rustup &>/dev/null; then
            log "Removing rustup installation"
            rustup self uninstall -y
        fi

        for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [[ -f "$rc_file" ]]; then
                log "Removing cargo PATH entries from $rc_file"
                sed -i.bak '/\.cargo\/bin/d' "$rc_file"
                rm -f "$rc_file.bak"
            fi
        done

        log "Cargo has been completely removed"
    fi

    success "Cargo tools uninstalled."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_cargo "$@"
fi
