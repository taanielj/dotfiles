#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

CLAUDE_SRC="$REPO_ROOT/.claude"
CLAUDE_DEST="$HOME/.claude"

main_claude() {
    configure_claude
}

configure_claude() {
    log "Configuring Claude Code..."

    ensure_real_dir "$CLAUDE_DEST"

    link_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DEST/CLAUDE.md"
    link_file "$CLAUDE_SRC/hooks/comment-lint.sh" "$CLAUDE_DEST/hooks/comment-lint.sh"
    link_file "$CLAUDE_SRC/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"

    link_commands
    install_settings

    success "Claude Code configuration completed."
}

link_commands() {
    ensure_real_dir "$CLAUDE_DEST/commands"

    local src
    for src in "$CLAUDE_SRC/commands"/*.md; do
        [[ -e "$src" ]] || continue
        link_file "$src" "$CLAUDE_DEST/commands/$(basename "$src")"
    done
}

# settings.json may hold secrets: seed from template only if absent, never link.
install_settings() {
    if [[ -e "$CLAUDE_DEST/settings.json" ]]; then
        log "  settings.json exists, leaving it untouched"
        return 0
    fi
    log "  seeding settings.json from template (edit in secrets afterwards)"
    cp "$CLAUDE_SRC/settings.json.template" "$CLAUDE_DEST/settings.json"
}

teardown_claude() {
    log "Removing Claude Code configuration..."

    unlink_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DEST/CLAUDE.md"
    unlink_file "$CLAUDE_SRC/hooks/comment-lint.sh" "$CLAUDE_DEST/hooks/comment-lint.sh"
    unlink_file "$CLAUDE_SRC/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"

    local dest
    for dest in "$CLAUDE_DEST/commands"/*.md; do
        [[ -L "$dest" ]] || continue
        unlink_file "$CLAUDE_SRC/commands/$(basename "$dest")" "$dest"
    done

    success "Claude Code configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_claude "$@"
fi
