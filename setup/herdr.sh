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
    link_file "$REPO_ROOT/herdr/bin/herdr-join.sh" "$HOME/.config/herdr/bin/herdr-join.sh"
    link_file "$REPO_ROOT/herdr/bin/herdr-scrollback.sh" "$HOME/.config/herdr/bin/herdr-scrollback.sh"
    link_file "$REPO_ROOT/herdr/bin/herdr-session.sh" "$HOME/.config/herdr/bin/herdr-session.sh"

    # Herd-side plugins the config binds to (seamless nvim<->herdr nav/resize).
    if ! herdr plugin list 2>/dev/null | grep -q "herdr-splits"; then
        run_quiet "Installing herdr-splits plugin" herdr plugin install lmilojevicc/herdr-splits.nvim --yes
    fi
    if ! herdr plugin list 2>/dev/null | grep -q "^- layouts"; then
        run_quiet "Installing herdr-pane-layouts plugin" herdr plugin install iurysza/herdr-pane-layouts --yes
    fi
    if ! herdr plugin list 2>/dev/null | grep -q "herdr-resurrect"; then
        run_quiet "Installing herdr-resurrect plugin" herdr plugin install ntindle/herdr-resurrect --yes
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
    unlink_file "$REPO_ROOT/herdr/bin/herdr-join.sh" "$HOME/.config/herdr/bin/herdr-join.sh"
    unlink_file "$REPO_ROOT/herdr/bin/herdr-scrollback.sh" "$HOME/.config/herdr/bin/herdr-scrollback.sh"
    unlink_file "$REPO_ROOT/herdr/bin/herdr-session.sh" "$HOME/.config/herdr/bin/herdr-session.sh"
    success "herdr configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_herdr "$@"
fi
