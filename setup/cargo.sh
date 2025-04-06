#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

TOOLS=(
    "eza"
    "zoxide"
    "bat"
    "ripgrep"
    "fd"
)

main_cargo() {
    install_cargo_tools
}

install_cargo_tools(){
    
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_cargo "$@"
fi


