#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

HERDR_BIN="$HOME/.local/bin/herdr"

# The Herdr app's mods and Claude Code's EDITOR setting call these scripts by
# bare name. Claude's settings env doesn't expand paths.
SHARED_BIN=(herdr-nvim herdr-open herdr-netspeed herdr-sysmon herdr-weather herdr-sync)

APP_HOME="$HOME/.config/herdr-app"
# The app reads these paths from its home and keeps its own state in the rest of the home.
# The app watches the links themselves. After editing a mod in the repo, run
# `touch -h` on the mod's link to reload the mod.
APP_FILES=(settings.json keys.json themes/ghostty.json layouts/dotfiles.json mods/keys mods/status mods/strip mods/files-icons bin)
COMMITTED_APP_ZOOM=1.0

main_herdr() {
    # brew installs herdr on macOS (setup/system.sh)
    if [[ "$OSTYPE" != "darwin"* ]]; then
        install_from_script herdr https://herdr.dev/install.sh herdr
    fi
    link_shared_bin
    configure_herdr
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_cask herdr-app || return 1
        install_from_script hc https://releases.herdr.dev/core/install.sh herdr-core
        configure_herdr_app
    fi
}

# Usage: install_from_script <command> <installer-url> <name>
install_from_script() {
    local cmd="$1" url="$2" name="$3"
    if command -v "$cmd" &>/dev/null; then
        log "✅ $name is already installed at $(command -v "$cmd")"
        return
    fi
    local installer
    if ! installer=$(fetch_installer "$url"); then
        error "❌ Failed to download the $name installer."
        return 1
    fi
    # The installers write to ~/.local/bin, which zprofile adds to PATH.
    run_quiet "Installing $name" sh -c "$installer"
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

    # herdr/tui/config.toml binds keys to these plugins' actions.
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

    herdr server reload-config &>/dev/null || true
    success "herdr configuration completed."
}

configure_herdr_app() {
    log "Configuring the Herdr app..."
    local file
    for file in "${APP_FILES[@]}"; do
        link_file "$REPO_ROOT/herdr/app/$file" "$APP_HOME/$file"
    done
    # The app writes its zoom level into settings.json on every zoom.
    # The herdr-zoom filter, which .gitattributes applies to settings.json, makes git see COMMITTED_APP_ZOOM instead.
    git -C "$REPO_ROOT" config filter.herdr-zoom.clean \
        "sed -E 's/\"zoom\": [0-9.]+/\"zoom\": $COMMITTED_APP_ZOOM/'"
    # The dotfiles layout docks the keys mod. layout.set also switches a running
    # app window to the layout.
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
