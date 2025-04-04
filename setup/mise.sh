#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    install_mise
    install_tools
}

install_mise() {
    # mise's install script is idempotent, so no need to check if it's already installed
    run_quiet "Installing mise" curl https://mise.run | sh
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        shell_name=$(basename "$rc" | cut -d. -f2)
        grep -q 'mise activate' "$rc" || echo "eval \"\$($HOME/.local/bin/mise activate $shell_name)\"" >>"$rc"
    done
}

install_tools() {
    cd "$REPO_ROOT" || return 1
    run_quiet "Installing tools" mise install
    for line in $(cat .tool-versions); do
        tool=$(echo "$line" | cut -d' ' -f1)
        version=$(echo "$line" | cut -d' ' -f2)
        mise config set tools.$tool $version
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi
