#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_mise() {
    run_quiet "Installing mise" curl https://mise.run | sh
    [[ grep -q "/.local/bin/mise" "$HOME/.bashrc" ]] || echo "eval \"$($HOME/.local/bin/mise activate bash)\"" >>"$HOME/.bashrc"
    [[ grep -q "/.local/bin/mise" "$HOME/.zshrc" ]] || echo "eval \"$($HOME/.local/bin/mise activate zsh)\"" >>"$HOME/.zshrc"
}



install_mise(){}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_mise "$@"
fi

