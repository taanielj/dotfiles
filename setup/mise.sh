#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    install_mise
    activate_mise
    unset mise
    mise_binary=$(which mise 2>/dev/null || echo "$HOME/.local/bin/mise")
    install_tools
}

teardown_mise() {
    log "Removing mise configuration..."

    # Clean up mise activation from shell rc files
    declare -A rc_files=(
        [bash]="$HOME/.bashrc"
        [zsh]="$HOME/.zshrc"
    )

    for shell in "${!rc_files[@]}"; do
        rc="${rc_files[$shell]}"
        if [[ -f "$rc" ]]; then
            log "Removing mise activation from $rc"
            grep -v "mise activate $shell" "$rc" >"$rc.tmp" || true
            mv "$rc.tmp" "$rc"
        fi
    done

    # Remove mise config directory
    if [[ -d "$HOME/.config/mise" ]]; then
        log "Removing mise config directory"
        rm -rf "$HOME/.config/mise"
    fi

    # Remove mise binary if installed locally
    if [[ -f "$HOME/.local/bin/mise" ]]; then
        log "Removing mise binary from ~/.local/bin"
        rm -f "$HOME/.local/bin/mise"
    fi

    success "Mise configuration removed."
}

install_mise() {
    # Check if mise is already installed
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

activate_mise() {
    # More robust shell detection
    current_shell=$(ps -p $$ -ocomm= | sed 's/^-//')
    if [[ -z "$current_shell" ]]; then
        error "Could not detect current shell for mise activation"
        exit 1
    fi

    eval "$("$mise_binary" activate "$current_shell")"
}

install_mise_from_script() {
    # Works on Linux and macOS, not Termux
    run_quiet "Installing mise" bash -c "curl https://mise.run | sh"
}



install_mise_termux() {
    # WIP, does not work yet properly
    warn "Use asdf for now, mise is not fully supported on termux yet"
    return 0
    run_quiet "Installing musl version of mise" bash -c "curl https://mise.jdx.dev/mise-latest-linux-arm64-musl > $HOME/.local/bin/mise"
    chmod +x "$HOME/.local/bin/mise"
    mkdir -p "$HOME/.config/mise"

    declare -A rc_files=(
        [bash]="$HOME/.bashrc"
        [zsh]="$HOME/.zshrc"
    )

    local certs_dir="$PREFIX/etc/tls/certs"
    mkdir -p "$certs_dir"
    ln -sf "$PREFIX/etc/tls/cert.pem" "$PREFIX/etc/tls/certs.pem"
    ln -sf "$PREFIX/etc/tls/cert.pem" "$certs_dir/ca-certificates.crt"

    for shell in "${!rc_files[@]}"; do
        rc="${rc_files[$shell]}"

        grep -q "mise activate $shell" "$rc" 2>/dev/null ||
            echo "eval \"\$($HOME/.local/bin/mise activate $shell)\"" >>"$rc"

        grep -q "proot -b" "$rc" 2>/dev/null || cat <<EOF >>"$rc"
mise() {
    proot -b $PREFIX/etc/resolv.conf -b $PREFIX/etc/tls:/etc/ssl mise "\$@"
}
EOF
    done
    activate_mise
}

install_tools() {
    cd "$REPO_ROOT" || return 1

    local toolfile="$REPO_ROOT/.tool-versions"
    [[ ! -f "$toolfile" ]] && error "Missing .tool-versions file" && exit 1

    mkdir -p "$HOME/.config/mise"
    touch "$HOME/.config/mise/config.toml"

    log "Parsing .tool-versions for available tools..."

    mapfile -t all_tools < <(awk '!/^#/ && NF { print $1 }' "$toolfile")

    if ! command -v fzf &>/dev/null; then
        error "fzf not found. Please install it to use interactive tool selection."
        exit 1
    fi

    log "📦 Select tools to install (use TAB to mark multiple, ENTER to confirm)"
    selected_tools=$(printf "%s\n" "${all_tools[@]}" | fzf --multi --prompt="Select tools: " --header="Use TAB to select, ENTER to confirm")

    if [[ -z "$selected_tools" ]]; then
        warn "⚠️  No tools selected. Skipping tool installation."
        return
    fi

    while IFS= read -r selected_tool; do
        version=$(awk -v tool="$selected_tool" '$1 == tool { print $2 }' "$toolfile")
        [[ -z "$version" ]] && warn "⚠️  Version not found for $selected_tool" && continue

        run_quiet "📦 Installing $selected_tool@$version" mise install "$selected_tool"
        mise config set "tools.$selected_tool" "$version"
    done <<<"$selected_tools"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi
