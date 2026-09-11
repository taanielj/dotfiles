#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

HERDR_BIN="$HOME/.local/bin/herdr"

main_herdr() {
    # macOS gets herdr from brew (setup/system.sh); elsewhere from herdr.dev.
    if [[ "$(uname -s)" != "Darwin" ]]; then
        install_herdr
    fi
    configure_herdr
}

install_herdr() {
    if command -v herdr &>/dev/null; then
        log "✅ herdr is already installed at $(command -v herdr)"
        return
    fi
    local installer
    if ! installer=$(fetch_installer https://herdr.dev/install.sh); then
        error "❌ Failed to download the herdr installer."
        return 1
    fi
    # The script installs to ~/.local/bin, which zprofile puts on PATH.
    run_quiet "Installing herdr" sh -c "$installer"
}

configure_herdr() {
    log "Configuring herdr..."
    if ! command -v herdr &>/dev/null; then
        warn "herdr is not installed. Skipping."
        return 1
    fi

    link_file "$REPO_ROOT/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    # The whole directory, so a new script is visible to herdr without rerunning setup.
    link_file "$REPO_ROOT/herdr/bin" "$HOME/.config/herdr/bin"

    # Herd-side plugins the config binds to (nvim<->herdr nav/resize).
    if ! herdr plugin list 2>/dev/null | grep -q "herdr-splits"; then
        run_quiet "Installing herdr-splits plugin" herdr plugin install lmilojevicc/herdr-splits.nvim --yes
    fi
    if ! herdr plugin list 2>/dev/null | grep -q "^- layouts"; then
        run_quiet "Installing herdr-pane-layouts plugin" herdr plugin install iurysza/herdr-pane-layouts --yes
    fi
    if ! herdr plugin list 2>/dev/null | grep -q "herdr-resurrect"; then
        run_quiet "Installing herdr-resurrect plugin" herdr plugin install ntindle/herdr-resurrect --yes
    fi
    # Lays out every new worktree workspace; builds itself with cargo on first use.
    if ! herdr plugin list 2>/dev/null | grep -q "herdr-plugin-workspace-manager"; then
        run_quiet "Installing herdr workspace-manager plugin" herdr plugin install razajamil/herdr-plugin-workspace-manager --yes
    fi
    local config_dir
    config_dir=$(herdr plugin config-dir herdr-plugin-workspace-manager)
    if [[ -n "$config_dir" ]]; then
        link_file "$REPO_ROOT/herdr/plugins/workspace-manager/config.yml" "$config_dir/config.yml"
    else
        warn "No herdr config dir for workspace-manager; skipping its config."
    fi
    # The lazygit popup behind prefix+g and nvim's <leader>gg.
    if ! herdr plugin list 2>/dev/null | grep -q "^- lazygit "; then
        run_quiet "Linking herdr lazygit plugin" herdr plugin link "$REPO_ROOT/herdr/plugins/lazygit"
    fi

    if ! herdr config check; then
        warn "herdr config check reported issues (see above)."
        return 1
    fi

    # Apply to a running server if there is one; harmless otherwise.
    herdr server reload-config &>/dev/null || true
    success "herdr configuration completed."
}

teardown_herdr() {
    log "Removing herdr configuration..."
    unlink_file "$REPO_ROOT/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    unlink_file "$REPO_ROOT/herdr/bin" "$HOME/.config/herdr/bin"
    if command -v herdr &>/dev/null; then
        unlink_file "$REPO_ROOT/herdr/plugins/workspace-manager/config.yml" \
            "$(herdr plugin config-dir herdr-plugin-workspace-manager)/config.yml"
        herdr plugin unlink lazygit &>/dev/null || true
    else
        warn "herdr is not installed. Skipping its plugin teardown."
    fi
    if [[ -f "$HERDR_BIN" ]]; then
        log "Removing herdr installation from $HERDR_BIN"
        rm -f "$HERDR_BIN"
    fi
    success "herdr configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_herdr "$@"
fi
