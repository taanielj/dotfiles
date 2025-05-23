#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    if [[ "$OSTYPE" == "linux-android" ]]; then
        install_mise_termux
        return 0
    else
        install_mise
    fi
    install_tools
}

activate_mise() {
    # More robust shell detection
    current_shell=$(ps -p $$ -ocomm= | sed 's/^-//')
    if [[ -z "$current_shell" ]]; then
        error "Could not detect current shell for mise activation"
        exit 1
    fi

    eval "$("$HOME/.local/bin/mise" activate "$current_shell")"
}

install_mise() {
    # Works on Linux and macOS, not Termux
    run_quiet "Installing mise" bash -c "curl https://mise.run | sh"

    declare -A rc_files=(
        [bash]="$HOME/.bashrc"
        [zsh]="$HOME/.zshrc"
    )

    for shell in "${!rc_files[@]}"; do
        rc="${rc_files[$shell]}"
        grep -q "mise activate $shell" "$rc" 2>/dev/null || {
            echo "eval \"\$($HOME/.local/bin/mise activate $shell)\"" >>"$rc"
        }
    done

    activate_mise
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
