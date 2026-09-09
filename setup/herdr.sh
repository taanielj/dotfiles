#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_herdr() {
    configure_herdr
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
    link_file "$REPO_ROOT/herdr/plugins/workspace-manager/config.yml" \
        "$(herdr plugin config-dir herdr-plugin-workspace-manager)/config.yml"

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
    unlink_file "$REPO_ROOT/herdr/plugins/workspace-manager/config.yml" \
        "$(herdr plugin config-dir herdr-plugin-workspace-manager)/config.yml"
    success "herdr configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_herdr "$@"
fi
