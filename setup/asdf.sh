#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

declare -A ASDF_PLUGINS
OS=$(uname -s)
main_asdf() {
    parse_tool_versions
    install_asdf
    install_asdf_plugins_from_file
}

parse_tool_versions() {
    local file=".tool-versions"
    [[ -f "$file" ]] || {
        error "No .tool-versions file found. Aborting."
        exit 1
    }
    while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        local tool version
        read -r tool version <<<"$line"
        ASDF_PLUGINS["$tool"]="$version"
    done <"$file"
    local success_mgs="Installing tools: "
    for plugin in "${!ASDF_PLUGINS[@]}"; do
        success_mgs+="[$plugin:${ASDF_PLUGINS[$plugin]}] "
    done
    success "$success_mgs"
    
}

install_asdf() {
    if [[ "$OS" == "Darwin" && -f "/opt/homebrew/bin/asdf" ]]; then
        success "asdf already installed"
        return
    fi
    local version="v0.16.0"
    local asdf_dir="$HOME/.asdf"

    export PATH="$asdf_dir:$asdf_dir/shims:$PATH"

    if command -v asdf &>/dev/null; then
        return
    fi

    _install_asdf_clone_or_checkout "$version" "$asdf_dir"
    _build_asdf_with_go "$asdf_dir"
    _add_asdf_path_to_shell_rc "$asdf_dir"

    if ! command -v go >/dev/null; then
        error "Go not found after asdf install. Aborting."
        exit 1
    fi
}

install_asdf_plugins_from_file() {
    log "Installing asdf plugins..."
    _check_alternatives  # Call this function to populate the alternatives array
    for plugin in "${!ASDF_PLUGINS[@]}"; do
        local alternative="${alternatives[$plugin]}"
        if [[ -n "$alternative" ]] && command -v "$alternative" &>/dev/null; then
            success "    [$plugin] already installed via $alternative"
            continue
        fi
        
        # Skip installing Java if SDKMAN is detected
        if [[ "$plugin" == "java" && command -v sdk &>/dev/null ]]; then
            success "    [$plugin] already installed via SDKMAN, skipping installation."
            continue
        fi
        
        _install_asdf_plugin "$plugin"
        _install_asdf_tool "$plugin" "${ASDF_PLUGINS[$plugin]}"
    done
    success "asdf plugins installed"
}

_install_asdf_clone_or_checkout() {
    local version="$1"
    local dir="$2"

    log -n "Installing asdf $version..."

    if [[ -d "$dir" && ! -d "$dir/.git" ]]; then
        error "$dir exists but is not a git repo. Remove or fix manually."
        exit 1
    elif [[ -d "$dir" ]]; then
        git -C "$dir" fetch --quiet
        git -C "$dir" checkout "$version" --quiet
    else
        git clone https://github.com/asdf-vm/asdf.git --branch "$version" "$dir" &>/dev/null || {
            error "Failed to clone asdf. Aborting."
            exit 1
        }
    fi
    success " Done"
}

_build_asdf_with_go() {
    local dir="$1"
    local go_version="${ASDF_PLUGINS["golang"]}"

    local legacy_asdf="$dir/bin/asdf"

    export PATH="$dir/shims:$PATH"

    run_quiet --silent "$legacy_asdf" plugin add golang
    run_quiet --silent "$legacy_asdf" install golang "$go_version"
    run_quiet --silent "$legacy_asdf" global golang "$go_version"
    run_quiet --silent "$legacy_asdf" reshim golang

    # ⛏️ Now use that Go version to build Go-native asdf
    echo "golang 1.24.1" >"$dir/.tool-versions"
    run_quiet --silent bash -c "PATH='$dir/shims:$PATH' make -C '$dir' build"
    rm -f "$dir/.tool-versions"

    export PATH="$dir:$dir/shims:$PATH"

    if ! command -v go &>/dev/null; then
        error "Go not found in PATH after install. Aborting."
        exit 1
    fi
    asdf reshim golang
}

_add_asdf_path_to_shell_rc() {
    local dir="$1"
    for rc in ~/.zshrc ~/.bashrc; do
        grep -q 'export PATH="\$HOME/.asdf/bin:\$HOME/.asdf/shims:\$PATH"' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"' >>"$rc"
    done
}

_check_alternatives() {
    declare -gA alternatives  # Declare alternatives as a global associative array
    alternatives["java"]="sdk"  # Check for SDKMAN for Java
    alternatives["python"]="pyenv"  # Check for pyenv for Python
    alternatives["ruby"]="rbenv"  # Check for rbenv for Ruby
    alternatives["nodejs"]="nvm"  # Check for nvm for Node.js
}

_install_asdf_plugin() {
    local plugin=$1
    if asdf plugin list | grep -q "$plugin" &>/dev/null 2>&1; then
        success "    [$plugin] asdf plugin already installed"
        return
    fi
    run_quiet "    Installing asdf plugin [$plugin]" asdf plugin add "$plugin"
}

_install_asdf_tool() {
    local plugin=$1
    local version=$2
    if ! asdf list "$plugin" 2>&1 | grep -q "$version" &>/dev/null 2>&1; then
        run_quiet "    Installing [$plugin $version]" asdf install "$plugin" "$version"
    else
        success "    [$plugin:$version] already installed"
    fi

    # Ensure the command is formatted correctly
    if ! run_quiet "    Setting [$plugin $version] as global" asdf global "$plugin" "$version"; then
        error "Failed to set [$plugin $version] as global. Please check if 'asdf' is properly installed."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_asdf "$@"
fi
