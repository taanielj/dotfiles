#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

# mikefarah's yq, whose `yq e` syntax zsh/modules/docker.zsh uses
GLOBAL_TOOLS=("yq@4")

main_mise() {
    install_mise
    install_tools
}

resolve_mise() {
    local path
    if command -v mise &>/dev/null; then
        path=$(command -v mise)
    else
        path="$HOME/.local/bin/mise"
    fi
    echo "$path"
}

teardown_mise() {
    log "Removing mise configuration..."

    if [[ -d "$HOME/.config/mise" ]]; then
        log "Removing mise config directory"
        rm -rf "$HOME/.config/mise"
    fi

    if [[ -f "$HOME/.local/bin/mise" ]]; then
        log "Removing mise binary from ~/.local/bin"
        rm -f "$HOME/.local/bin/mise"
    fi

    success "Mise configuration removed."
}

install_mise() {
    if command -v mise &>/dev/null; then
        log "mise is already installed, skipping installation."
        return 0
    fi
    if [[ "$OSTYPE" == "linux-android" ]]; then
        install_mise_termux
        return 0
    else
        install_mise_from_script
    fi
}

install_mise_from_script() {
    local installer
    if ! installer=$(fetch_installer https://mise.run); then
        error "❌ Failed to download the mise installer."
        return 1
    fi
    run_quiet "Installing mise" sh -c "$installer"
}

install_mise_termux() {
    warn "Use asdf for now, mise is not fully supported on termux yet"
    return 0
}

install_tools() {
    cd "$REPO_ROOT" || return 1

    local toolfile="$REPO_ROOT/.tool-versions"
    [[ ! -f "$toolfile" ]] && error "Missing .tool-versions file" && exit 1

    mkdir -p "$HOME/.config/mise"
    touch "$HOME/.config/mise/config.toml"

    log "Parsing .tool-versions for available tools..."

    local all_tools=() tool
    while IFS= read -r tool; do
        all_tools+=("$tool")
    done < <(awk '!/^#/ && NF { print $1 "@" $2 }' "$toolfile")
    all_tools+=("${GLOBAL_TOOLS[@]}")

    log "📦 Install tools from .tool-versions and ${GLOBAL_TOOLS[*]}?"
    install_mode=$(interactive_choice "Choose action: " "All" "Custom" "Skip")

    case "$install_mode" in
    "Skip" | "")
        warn "⚠️  Skipping tool installation."
        return 0
        ;;
    "All")
        log "📦 Installing all tools..."
        selected_tools=$(printf "%s\n" "${all_tools[@]}")
        ;;
    "Custom")
        log "📦 Select tools to install:"
        selected_tools=$(interactive_multi_choice "Select tools: " "${all_tools[@]}")

        if [[ -z "$selected_tools" ]]; then
            warn "⚠️  No tools selected. Skipping tool installation."
            return 0
        fi
        ;;
    esac

    local mise_bin
    mise_bin=$(resolve_mise)

    while IFS= read -r selected_tool_version; do
        [[ -z "$selected_tool_version" ]] && continue

        # --global records the tool in ~/.config/mise/config.toml
        run_quiet "📦 Installing $selected_tool_version" "$mise_bin" use --global "$selected_tool_version"
    done <<<"$selected_tools"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi
