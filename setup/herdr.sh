#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

HERDR_BIN="$HOME/.local/bin/herdr"

# Scripts both herdr and the Herdr app run, linked onto PATH: Claude Code's
# EDITOR (a name its settings env can give: env values are not expanded), the
# Files panel's open-in-nvim and the status bars' network, system and weather
# readouts.
SHARED_BIN=(herdr-nvim herdr-open herdr-netspeed herdr-sysmon herdr-weather)

APP_HOME="$HOME/.config/herdr-app"
# Files the app reads from its home; everything else there is the app's own state.
# The app's file events don't follow these links: after editing a mod in the
# repo, `touch -h` its link to reload it.
APP_FILES=(settings.json keys.json themes/ghostty.json layouts/dotfiles.json mods/keys mods/status mods/strip mods/files-icons bin)
# The zoom level committed in settings.json, whatever the app last zoomed to.
APP_ZOOM=1.0

main_herdr() {
    # macOS gets herdr from brew (setup/system.sh); elsewhere from herdr.dev.
    if [[ "$OSTYPE" != "darwin"* ]]; then
        install_herdr
    fi
    link_shared_bin
    configure_herdr
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_cask herdr-app || return 1
        install_herdr_core
        configure_herdr_app
    fi
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

install_herdr_core() {
    if command -v hc &>/dev/null; then
        log "✅ herdr-core is already installed at $(command -v hc)"
        return
    fi
    local installer
    if ! installer=$(fetch_installer https://releases.herdr.dev/core/install.sh); then
        error "❌ Failed to download the herdr-core installer."
        return 1
    fi
    # The script installs to ~/.local/bin, which zprofile puts on PATH.
    run_quiet "Installing herdr-core" sh -c "$installer"
}

link_shared_bin() {
    local name
    for name in "${SHARED_BIN[@]}"; do
        link_file "$REPO_ROOT/herdr/bin/$name.sh" "$HOME/.local/bin/$name"
    done
}

configure_herdr() {
    log "Configuring herdr..."
    if ! command -v herdr &>/dev/null; then
        warn "herdr is not installed. Skipping."
        return 1
    fi

    link_file "$REPO_ROOT/herdr/tui/config.toml" "$HOME/.config/herdr/config.toml"
    # The whole directory, so a new script is visible to herdr without rerunning setup.
    link_file "$REPO_ROOT/herdr/tui/bin" "$HOME/.config/herdr/bin"

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
        link_file "$REPO_ROOT/herdr/tui/plugins/workspace-manager/config.yml" "$config_dir/config.yml"
    else
        warn "No herdr config dir for workspace-manager; skipping its config."
    fi
    # The lazygit popup behind prefix+g and nvim's <leader>gg.
    if ! herdr plugin list 2>/dev/null | grep -q "^- lazygit "; then
        run_quiet "Linking herdr lazygit plugin" herdr plugin link "$REPO_ROOT/herdr/tui/plugins/lazygit"
    fi
    # Reruns the programs in herdr/tui/plugins/restore/programs after a server restart.
    if ! herdr plugin list 2>/dev/null | grep -q "^- restore "; then
        run_quiet "Linking herdr restore plugin" herdr plugin link "$REPO_ROOT/herdr/tui/plugins/restore"
    fi
    # Sets the $title sidebar token the agent rows in config.toml show.
    if ! herdr plugin list 2>/dev/null | grep -q "^- agent-titles "; then
        run_quiet "Linking herdr agent-titles plugin" herdr plugin link "$REPO_ROOT/herdr/tui/plugins/agent-titles"
    fi
    # Sets the $tab sidebar token the space rows in config.toml show.
    if ! herdr plugin list 2>/dev/null | grep -q "^- active-tab "; then
        run_quiet "Linking herdr active-tab plugin" herdr plugin link "$REPO_ROOT/herdr/tui/plugins/active-tab"
    fi

    if ! herdr config check; then
        warn "herdr config check reported issues (see above)."
        return 1
    fi

    # Apply to a running server if there is one; harmless otherwise.
    herdr server reload-config &>/dev/null || true
    success "herdr configuration completed."
}

configure_herdr_app() {
    log "Configuring the Herdr app..."
    local file
    for file in "${APP_FILES[@]}"; do
        link_file "$REPO_ROOT/herdr/app/$file" "$APP_HOME/$file"
    done
    # The app writes its zoom level into settings.json on every zoom; git sees the
    # committed level instead (filter named in .gitattributes).
    git -C "$REPO_ROOT" config filter.herdr-zoom.clean \
        "sed -E 's/\"zoom\": [0-9.]+/\"zoom\": $APP_ZOOM/'"
    # The layout docks the keys mod; a running window switches to it now.
    herdr-app "do" layout.set --layout dotfiles &>/dev/null || true
    success "Herdr app configuration linked."
}

teardown_herdr() {
    log "Removing herdr configuration..."
    unlink_file "$REPO_ROOT/herdr/tui/config.toml" "$HOME/.config/herdr/config.toml"
    unlink_file "$REPO_ROOT/herdr/tui/bin" "$HOME/.config/herdr/bin"
    local name
    for name in "${SHARED_BIN[@]}"; do
        unlink_file "$REPO_ROOT/herdr/bin/$name.sh" "$HOME/.local/bin/$name"
    done
    if command -v herdr &>/dev/null; then
        unlink_file "$REPO_ROOT/herdr/tui/plugins/workspace-manager/config.yml" \
            "$(herdr plugin config-dir herdr-plugin-workspace-manager)/config.yml"
        herdr plugin unlink lazygit &>/dev/null || true
        herdr plugin unlink restore &>/dev/null || true
    else
        warn "herdr is not installed. Skipping its plugin teardown."
    fi
    if [[ -f "$HERDR_BIN" ]]; then
        log "Removing herdr installation from $HERDR_BIN"
        rm -f "$HERDR_BIN"
    fi
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local file
        for file in "${APP_FILES[@]}"; do
            unlink_file "$REPO_ROOT/herdr/app/$file" "$APP_HOME/$file"
        done
        git -C "$REPO_ROOT" config --unset filter.herdr-zoom.clean || true
        uninstall_cask herdr-app
    fi
    success "herdr configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_herdr "$@"
fi
