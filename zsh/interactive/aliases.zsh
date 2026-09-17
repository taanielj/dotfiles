
if command -v nvim &>/dev/null; then
    alias vim=nvim

    # Drop this directory's auto-session and start nvim clean. The filename
    # mirrors auto-session's encoding of the cwd (/ and . percent-encoded).
    nvf() {
        local enc=${PWD//\//%2F}
        enc=${enc//./%2E}
        rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/sessions/${enc}.vim"
        nvim "$@"
    }
fi
if command -v bat &>/dev/null; then
    alias cat="bat -p --paging=never"
    alias less="bat -p --paging=always"
    alias more="bat -p --paging=always"
    tailf() { tail -f "$@" | bat -p --paging=never -l log }
    # roff overstrikes and SGR codes stripped before the man lexer
    export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -l man'"
    alias -g -- --help='--help 2>&1 | bat -p -l help'
fi

alias x="exit"
envload() {
    if [[ ! -f .env ]]; then
        echo "No .env file in $(pwd)"
        return 1
    fi
    setopt localoptions allexport
    source ./.env
    echo "Loaded $(grep -cvE '^[[:space:]]*(#|$)' .env) var(s) from .env"
}

if command -v eza &>/dev/null; then
    alias l="eza"
    alias ls="eza --group-directories-first --icons --color=auto --git -h"
    alias tree="eza --tree"
else
    alias l="ls"
    alias ls="ls --color=auto"
fi
alias la="ls -la"

alias cl="clear && printf '\e[3J'"
alias cle="clear && printf '\e[3J' && exec zsh"
alias cld="cd && clear && printf '\e[3J' && exec zsh"

nvim() {
    local term=$TERM
    # xterm-kitty terminfo gives nvim a blinking cursor
    [[ "$TERM_PROGRAM" == "kitty" ]] && term="xterm-kitty"
    if [[ -z $VIRTUAL_ENV && -x .venv/bin/python ]]; then
        TERM=$term VIRTUAL_ENV="$PWD/.venv" PATH="$PWD/.venv/bin:$PATH" command nvim "$@"
        return
    fi
    TERM=$term command nvim "$@"
}

nvimf() {
    local dir=${1:-.} file
    file=$(cd "$dir" && FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf) || return
    nvim "$dir/$file"
}

alias gflog='git log --follow --stat --date=format:%Y-%m-%d --pretty=format:"%C(yellow)%h%Creset %C(cyan)%cd%Creset %s %C(auto)%d%Creset%n" --'

_todo_backend() {
    if command -v rg &>/dev/null; then
        echo rg
    elif command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
        echo git
    elif command -v grep &>/dev/null; then
        echo grep
    else
        echo "todos: needs rg, git (inside a repo) or grep, none found" >&2
        return 1
    fi
}
_todo_grep() {
    local backend=$1 mode=$2; shift 2
    # todo-comments.nvim's default keywords
    local pattern='(^|[^[:alnum:]_])(TODO|FIX|FIXME|BUG|FIXIT|ISSUE|HACK|WARN|WARNING|XXX|PERF|OPTIM|OPTIMIZE|PERFORMANCE|NOTE|INFO|TEST|TESTING|PASSED|FAILED):'
    local -a opts=(-nH --color=never)
    [[ $mode == verbose ]] && opts=(-nH -C 3 --color=always)

    case $backend in
        rg)   rg "${opts[@]}" -e "$pattern" -- "$@" ;;
        git)  git --no-pager grep -EI --untracked "${opts[@]}" -e "$pattern" -- "$@" ;;
        grep) grep -rEI --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv "${opts[@]}" -e "$pattern" -- "$@" ;;
    esac
}
todos() {
    local backend
    backend=$(_todo_backend) || return 1
    setopt localoptions pipefail
    _todo_grep "$backend" terse "$@" | cut -d: -f1,2
}
todosv() {
    if ! command -v bat &>/dev/null; then
        local backend
        backend=$(_todo_backend) || return 1
        _todo_grep "$backend" verbose "$@"
        return
    fi
    setopt localoptions pipefail
    local file line
    todos "$@" | while IFS=: read -r file line; do
        bat --style=header,numbers --color=always --paging=never \
            --highlight-line "$line" --line-range "$(( line > 3 ? line - 3 : 1 )):$(( line + 3 ))" -- "$file"
    done
}

if command -v claude &>/dev/null; then
    alias clask='claude -p'
    clmd() {
        claude -p --model haiku "Output ONLY a single bash command, no explanation, no markdown, no backticks. Task: $*" | pbcopy
        echo "copied"
    }
fi

# Reads "id<TAB>label" lines and prints the id picked in fzf; $2 previews {1}, the id.
_pick_session() {
    fzf --prompt="$1" --delimiter='\t' --with-nth=2.. --preview="$2" --preview-window=right:60%:wrap | cut -f1
}

_mtime() { zmodload -F zsh/stat b:zstat; zstat -F "%Y-%m-%d %H:%M" +mtime "$1" }

# Resume an Antigravity conversation that mentions this directory.
agyr() {
    local brain_dir="$HOME/.gemini/antigravity-cli/brain"
    local file id lines=()
    for file in $(grep -l "$PWD" "$brain_dir"/*/.system_generated/logs/transcript.jsonl 2>/dev/null); do
        lines+=("${${file#$brain_dir/}%%/*}\t$(_mtime "$file")")
    done
    (( ${#lines} )) || { echo "No conversations found for $PWD" >&2; return 1 }
    id=$(print -l -- "${lines[@]}" | _pick_session "Resume conversation: " \
        "jq -r 'select(.type==\"USER_INPUT\") | .content | split(\"<USER_REQUEST>\\n\")[1] // empty | \"❯ \" + split(\"\\n</USER_REQUEST>\")[0]' \"$brain_dir/\"{1}/.system_generated/logs/transcript.jsonl")
    [[ -n "$id" ]] && agy --conversation "$id"
}

# Resume a Claude Code session started in this directory, listed by title.
clauder() {
    local dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/${${PWD//\//-}//./-}"
    local file id title lines=()
    for file in "$dir"/*.jsonl(Nom); do
        title=$(grep -h '"type":"ai-title"\|"type":"last-prompt"' "$file" |
            jq -rs '(map(select(.type=="ai-title")) | last | .aiTitle) // (map(select(.type=="last-prompt")) | last | .lastPrompt) // "(untitled)"')
        lines+=("${file:t:r}\t$(_mtime "$file")  $title")
    done
    (( ${#lines} )) || { echo "No Claude sessions for $PWD" >&2; return 1 }
    id=$(print -l -- "${lines[@]}" | _pick_session "Resume session: " \
        "jq -r 'select(.type==\"last-prompt\") | \"❯ \" + .lastPrompt' \"$dir/\"{1}.jsonl | uniq")
    [[ -n "$id" ]] && claude --resume "$id"
}
