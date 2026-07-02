#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

CLAUDE_SRC="$REPO_ROOT/.claude"
CLAUDE_DEST="$HOME/.claude"
# Private overrides from a sibling notes repo, if cloned.
NOTES_SRC="${CLAUDE_NOTES_DIR:-$REPO_ROOT/../notes/.claude}"

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

# Link commands; a same-named notes command wins over the dotfiles default.
link_commands() {
    ensure_real_dir "$CLAUDE_DEST/commands"

    local name src
    for src in "$CLAUDE_SRC/commands"/*.md; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        if [[ -f "$NOTES_SRC/commands/$name" ]]; then
            log "  $name: using notes override"
            link_file "$NOTES_SRC/commands/$name" "$CLAUDE_DEST/commands/$name"
        else
            link_file "$src" "$CLAUDE_DEST/commands/$name"
        fi
    done

    # notes-only commands
    if [[ -d "$NOTES_SRC/commands" ]]; then
        for src in "$NOTES_SRC/commands"/*.md; do
            [[ -e "$src" ]] || continue
            name=$(basename "$src")
            [[ -f "$CLAUDE_SRC/commands/$name" ]] && continue
            link_file "$src" "$CLAUDE_DEST/commands/$name"
        done
    fi

    # notes-only: memory and skills
    [[ -d "$NOTES_SRC/memory" ]] && link_file "$NOTES_SRC/memory" "$CLAUDE_DEST/memory"
    [[ -d "$NOTES_SRC/skills" ]] && link_file "$NOTES_SRC/skills" "$CLAUDE_DEST/skills"
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

    local name dest
    for dest in "$CLAUDE_DEST/commands"/*.md; do
        [[ -L "$dest" ]] || continue
        name=$(basename "$dest")
        unlink_file "$CLAUDE_SRC/commands/$name" "$dest"
        unlink_file "$NOTES_SRC/commands/$name" "$dest"
    done

    unlink_file "$NOTES_SRC/memory" "$CLAUDE_DEST/memory"
    unlink_file "$NOTES_SRC/skills" "$CLAUDE_DEST/skills"

    success "Claude Code configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_claude "$@"
fi
