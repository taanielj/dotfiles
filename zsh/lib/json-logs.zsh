# Streams stdin, pretty-printing JSON log lines and passing others through.
_pipe_json_if_valid() {
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
