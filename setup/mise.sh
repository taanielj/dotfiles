#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    install_mise
    install_tools
}

install_mise() {
    # mise's install script is idempotent, so no need to check if it's already installed
    run_quiet "Installing mise" bash -c "curl https://mise.run | sh"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        shell_name=$(basename "$rc" | cut -d. -f2)
        grep -q 'mise activate' "$rc" || echo "eval \"\$($HOME/.local/bin/mise activate $shell_name)\"" >>"$rc"
    done
    # activate for current shell
    eval "$($HOME/.local/bin/mise activate bash)"
}

install_tools() {
    cd "$REPO_ROOT" || return 1
    run_quiet "Installing tools" mise install
    mkdir -p "$HOME/.config/mise"
    touch $HOME/.config/mise/config.toml
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        tool=$(echo "$line" | cut -d' ' -f1)
        version=$(echo "$line" | cut -d' ' -f2)
        mise config set "tools.$tool" "$version"
    done <"$REPO_ROOT/.tool-versions"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi
