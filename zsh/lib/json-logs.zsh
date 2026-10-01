# Streams stdin, pretty-printing JSON log lines and colouring the whole stream as a log.
jsonl() {
    # Command form merges stderr, where loggers usually write
    if (( $# )); then
        setopt localoptions pipefail
        "$@" 2>&1 | jsonl
        return
    fi
    if command -v bat &>/dev/null; then
        _jsonl_pretty | bat -pp -l log --color=always
    else
        _jsonl_pretty
    fi
}

# bat mangles pre-coloured input, so JSON stays uncoloured here and gets the log colours downstream
_jsonl_pretty() {
    local line content parsed
    while IFS= read -r line; do
        content="$line"
        # Strip a leading timestamp so JSON detection works
        if [[ "$line" =~ '^[0-9TZ:.+-]+[[:space:]]+(\{.*\})[[:space:]]*$' ]]; then
            content="$match[1]"
        fi

        if [[ "$content" == \{*\} ]] && parsed=$(print -r -- "$content" | jq . 2>/dev/null); then
            print -r -- "$parsed"
        else
            print -r -- "$line"
        fi
    done
}
