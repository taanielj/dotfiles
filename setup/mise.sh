#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    install_mise
    install_tools
}

install_mise() {
    run_quiet "Installing mise" bash -c "curl https://mise.run | sh"
    declare -A rc_files=(
        [bash]="$HOME/.bashrc"
        [zsh]="$HOME/.zshrc"
    )
    for shell in "${!rc_files[@]}"; do
        rc="${rc_files[$shell]}"
        grep -q "mise activate $shell" "$rc" 2>/dev/null ||
            echo "eval \"\$($HOME/.local/bin/mise activate $shell)\"" >>"$rc"
    done
    current_shell=$(basename "$SHELL")
    eval "$($HOME/.local/bin/mise activate "$current_shell")"
}

install_tools() {
    cd "$REPO_ROOT" || return 1

    mkdir -p "$HOME/.config/mise"
    touch "$HOME/.config/mise/config.toml"

    log "Installing tools from .tool-versions"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        tool=$(echo "$line" | awk '{print $1}')
        version=$(echo "$line" | awk '{print $2}')

        run_quiet "📦 Installing $tool@$version" mise install "$tool"

        mise config set "tools.$tool" "$version"
    done <"$REPO_ROOT/.tool-versions"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi
