# Streams stdin, pretty-printing JSON log lines and passing others through.
jsonl() {
    # Command form merges stderr, where loggers usually write
    if (( $# )); then
        setopt localoptions pipefail
        "$@" 2>&1 | jsonl
        return
    fi
    local line content parsed
    while IFS= read -r line; do
        content="$line"
        # Strip a leading timestamp so JSON detection works
        if [[ "$line" =~ '^[0-9TZ:.+-]+[[:space:]]+(\{.*\})[[:space:]]*$' ]]; then
            content="$match[1]"
        fi

        [[ "$content" == \{*\} ]] || { print -r -- "$line"; continue }

        if parsed=$(print -r -- "$content" | jq . 2>/dev/null); then
            if command -v bat &>/dev/null; then
                print -r -- "$parsed" | bat --color=always --language=json --style=plain --paging=never
            else
                print -r -- "$parsed"
            fi
        else
            print -r -- "$line"
        fi
    done
}
