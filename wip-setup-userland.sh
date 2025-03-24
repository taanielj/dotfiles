#!/usr/bin/env bash

source logging.sh
set -e

install_asdf() {
    if [ -d ~/.asdf ]; then
        log "asdf already installed"
        #cd ~/.asdf && git pull >/dev/null || { error "failed to update asdf" && exit 1; }
        #success "done"
    else
        log -n "Installing asdf..."
        git clone https://github.com/asdf-vm/asdf.git --branch v0.16.0 ~/.asdf >/dev/null
    fi
}

# asdf is not exported to path yet, let's use full path for now
asdf=~/.asdf/bin/asdf

install_asdf_plugins() {
    local plugins=("$@")
    log -n "Installing asdf plugins..."
    for plugin in "${plugins[@]}"; do
        log -n "    Installing $plugin..."
        ~/.asdf/bin/asdf plugin add $plugin >/dev/null 2>&1 || true
        success " done"
    done
    success " done"
}

install_asdf_tool() {
    local plugin=$1
    local version=$2

    log -n "Checking "$plugin $version"..."

    if ! ~/.asdf/bin/asdf list $plugin | grep -q $version; then
        log -n "    Installing $plugin $version..."
        ~/.asdf/bin/asdf install $plugin $version >/dev/null || { error "Failed to install $plugin $version" && exit 1; }
        success " done"
    else
        success " already installed"
    fi

    log -n "    setting $plugin $version as global..."
    ~/.asdf/bin/asdf global $plugin $version >/dev/null || { error "Failed to set $plugin $version as global" && exit 1; }
}

install_asdf
install_asdf_plugins "nodejs" "python" "golang" "java" # "ruby" (not needed for now, check on work laptop when needed)
# install_asdf_tool "nodejs" "22.11.0"
lts_version=$(asdf cmd nodejs resolve lts)
install_asdf_tool "nodejs" $lts_version
install_asdf_tool "python" "3.12.9"
install_asdf_tool "golang" "1.24.1"
install_asdf_tool "java" "21.0.6-zulu"

