# Streams stdin, pretty-printing JSON log lines and passing others through.
_pipe_json_if_valid() {
    local line content parsed
    while IFS= read -r line; do
        content="$line"
        # Strip a leading timestamp so JSON detection works
        if [[ "$line" =~ '^[0-9TZ:.+-]+[[:space:]]+(\{.*\})[[:space:]]*$' ]]; then
            content="$match[1]"
        fi

        [[ "$content" == \{*\} ]] || { echo "$line"; continue }

        if parsed=$(echo "$content" | jq . 2>/dev/null); then
            if command -v bat &>/dev/null; then
                echo "$parsed" | bat --color=always --language=json --style=plain --paging=never
            else
                echo "$parsed"
            fi
        else
            echo "$line"
        fi
    done
}
