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
APP_FILES=(settings.json keys.json themes/ghostty.json layouts/dotfiles.json mods/keys mods/status mods/strip mods/files-icons mods/copy-mode bin)
COMMITTED_APP_ZOOM=1.0

# Copied to the Windows app on WSL (no links without Developer Mode); rerun setup after edits
WINDOWS_APP_FILES=(themes/ghostty.json layouts/dotfiles.json mods/keys mods/status mods/strip mods/files-icons)

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
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        configure_herdr_app_windows
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

# Prints the Windows app's home as a Linux path
windows_app_home() {
    local profile
    # cmd.exe warns when started from a Linux folder
    profile=$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r') && [[ -n "$profile" ]] || return 1
    echo "$(wslpath -u "$profile")/.config/herdr-app"
}

# keys.json for Windows: Cmd -> Ctrl, Ctrl+1-9 -> Alt+1-9, no Ctrl+Alt+<char> (AltGr)
windows_keys() {
    jq '
        def chords: gsub("(?<s>^| )cmd-"; "\(.s)ctrl-");
        .global |= with_entries(
            select(.value | test("^(app\\.(quit|hide|hide_others|show_all)|keys\\.window-)") | not)
            | .key |= (sub("^ctrl-(?<n>[1-9])$"; "alt-\(.n)") | chords)
            | select(.key | test("(^| )ctrl-alt-[^ ]$|^ctrl-[][]$") | not))
        | .terminal |= {
            "ctrl-backspace": "send:\u0017", "ctrl-left": "send:\u001bb", "ctrl-right": "send:\u001bf",
            "ctrl-shift-c": "terminal.copy", "ctrl-shift-v": "terminal.paste", "ctrl-shift-f": "terminal.search",
            "ctrl-v": "terminal.paste_image", "ctrl-insert": "terminal.copy", "shift-insert": "terminal.paste"
        } + with_entries(select((.key | startswith("cmd-")) and (.value | startswith("send:")) | not) | .key |= chords)
    ' "$REPO_ROOT/herdr/app/keys.json"
}

# Usage: set_windows_setting <app-home> <jq-filter>
set_windows_setting() {
    local settings="$1/settings.json" updated
    [[ -f "$settings" ]] || echo '{}' >"$settings"
    updated=$(jq "$2" "$settings") && printf '%s\n' "$updated" >"$settings"
}

configure_herdr_app_windows() {
    if ! command -v herdr-app.exe &>/dev/null; then
        warn "The Herdr app is not installed on Windows. Skipping."
        return 0
    fi
    log "Configuring the Herdr app on Windows..."
    # For the app's terminals on this distro
    link_file "$REPO_ROOT/herdr/app/bin" "$APP_HOME/bin"
    link_file "$REPO_ROOT/herdr/bin/herdr-app-wsl.sh" "$HOME/.local/bin/herdr-app"

    local home file
    home=$(windows_app_home) || {
        error "❌ Could not find the Windows user folder."
        return 1
    }
    for file in "${WINDOWS_APP_FILES[@]}"; do
        rm -rf "${home:?}/$file"
        mkdir -p "$(dirname "$home/$file")"
        cp -r "$REPO_ROOT/herdr/app/$file" "$home/$file"
    done
    if [[ -e "$home/keys.json" ]] && ! compgen -G "$home/keys.json.backup.*" >/dev/null; then
        backup_file "$home/keys.json"
    fi
    windows_keys >"$home/keys.json"
    # Only the theme; zoom and fonts stay Windows' own
    set_windows_setting "$home" '.theme = "ghostty"'
    herdr-app.exe "do" layout.switch --name dotfiles &>/dev/null || true
    success "Herdr app on Windows configured."
}

teardown_herdr_app_windows() {
    unlink_file "$REPO_ROOT/herdr/app/bin" "$APP_HOME/bin"
    unlink_file "$REPO_ROOT/herdr/bin/herdr-app-wsl.sh" "$HOME/.local/bin/herdr-app"
    local home file
    home=$(windows_app_home) || return 0
    herdr-app.exe "do" layout.switch --name main &>/dev/null || true
    set_windows_setting "$home" 'if .theme == "ghostty" then del(.theme) else . end'
    for file in "${WINDOWS_APP_FILES[@]}"; do
        rm -rf "${home:?}/$file"
    done
    rm -f "$home/keys.json"
    restore_backup "$home/keys.json"
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
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        teardown_herdr_app_windows
    fi
    success "herdr configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_herdr "$@"
fi
