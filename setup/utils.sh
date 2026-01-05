# ANSI colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Logging functions

log() {
    if [[ "$1" == "-n" ]]; then
        shift
        echo -ne "${BLUE}$*${RESET}"
    else
        echo -e "${BLUE}$*${RESET}"
    fi
}

warn() {
    echo -e "${ORANGE}$*${RESET}"
}

error() {
    echo -e "${RED}$*${RESET}"
}

success() {
    if [[ "$1" == "-n" ]]; then
        shift
        echo -ne "${GREEN}$*${RESET}"
    else
        echo -e "${GREEN}$*${RESET}"
    fi
}

divider() {
    local length=80
    echo -e "${GREEN}$(printf "%${length}s" | tr ' ' '-')${RESET}"
}
title() {
    local title="$1"
    local length=80
    local title_length=${#title}
    local title_padding=$((($length - $title_length - 2) / 2))
    echo -e "${GREEN}$(printf "%${title_padding}s" | tr ' ' '-') $title $(printf "%${title_padding}s" | tr ' ' '-')${RESET}"
}

run_quiet() {
    local silent=0
    local description=""
    if [[ "$1" == "--silent" ]]; then
        silent=1
        shift
    else
        description="$1"
        shift
    fi

    if [[ "$silent" -eq 0 && -n "$description" ]]; then
        log -n "$description..."
    fi

    if ! output=$("$@" 2>&1 >/dev/null); then
        if [[ "$silent" -eq 0 && -n "$description" ]]; then
            printf "\n"
            error "❌ Failed: $description"
        fi
        echo "$output" >&2
        exit 1
    fi

    if [[ "$silent" -eq 0 && -n "$description" ]]; then
        success " Done"
    fi
}

# Interactive single selection with fzf or bash fallback
# Usage: interactive_choice "prompt" "option1" "option2" "option3" ...
interactive_choice() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v fzf &>/dev/null; then
        printf "%s\n" "${options[@]}" | fzf --height=40% --prompt="$prompt"
    else
        echo "$prompt"
        select choice in "${options[@]}"; do
            [[ -n "$choice" ]] && echo "$choice" && break
        done
    fi
}

# Interactive multi-selection with fzf or bash fallback
# Usage: interactive_multi_choice "prompt" "${array[@]}"
interactive_multi_choice() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v fzf &>/dev/null; then
        printf "%s\n" "${options[@]}" | fzf --multi --prompt="$prompt" --header="TAB to select, ENTER to confirm"
    else
        echo "$prompt"
        echo "Enter numbers separated by spaces (e.g., '1 3 5'), or 'all' for everything:"

        for i in "${!options[@]}"; do
            echo "$((i+1))) ${options[$i]}"
        done

        echo -n "Selection: "
        read -r input

        if [[ "$input" == "all" ]]; then
            printf "%s\n" "${options[@]}"
        else
            for num in $input; do
                idx=$((num - 1))
                [[ $idx -ge 0 && $idx -lt ${#options[@]} ]] && echo "${options[$idx]}"
            done
        fi
    fi
}
