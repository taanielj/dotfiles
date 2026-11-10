#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

SPF_BIN="$HOME/.local/bin/spf"

main_superfile() {
    install_superfile
}

# No apt package. brew installs superfile on macOS (setup/system.sh).
install_superfile() {
    local version arch current_version
    version=$(github_latest_version yorukot/superfile)
    [[ -z "$version" ]] && error "Could not determine the latest superfile version" && return 1
    case "$(release_archive_arch)" in
    x86_64) arch=amd64 ;;
    arm64) arch=arm64 ;;
    *) error "Unsupported architecture for superfile: $(uname -m)" && return 1 ;;
    esac

    if [[ -x "$SPF_BIN" ]]; then
        current_version=$("$SPF_BIN" -v 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
        if [[ "$current_version" == "$version" ]]; then
            log "✅ superfile is already up to date (v$current_version)"
            return
        fi
        log "⏫ superfile is outdated (v$current_version), updating to v$version"
    else
        log "📦 Installing superfile v$version"
    fi

    mkdir -p "$HOME/.local/bin"
    local tmp_dir name
    tmp_dir=$(mktemp -d)
    name="superfile-linux-v${version}-${arch}"
    run_quiet "Downloading superfile" curl -fsSL "https://github.com/yorukot/superfile/releases/download/v${version}/${name}.tar.gz" \
        -o "$tmp_dir/superfile.tar.gz"
    run_quiet "Extracting superfile" tar -xzf "$tmp_dir/superfile.tar.gz" -C "$tmp_dir"
    install -m 755 "$tmp_dir/dist/$name/spf" "$SPF_BIN" || return 1
    rm -rf "$tmp_dir"

    log "✅ superfile v$version installed to $SPF_BIN"
}

teardown_superfile() {
    if [[ -f "$SPF_BIN" ]]; then
        log "Removing superfile installation from $SPF_BIN"
        rm -f "$SPF_BIN"
        success "superfile uninstalled."
    else
        log "superfile is not installed at $SPF_BIN. Nothing to do."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_superfile "$@"
fi
