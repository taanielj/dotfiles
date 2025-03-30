# Aliases configuration
if command -v nvim &> /dev/null; then
  alias vim=nvim
fi
if command -v bat &> /dev/null; then
  alias cat="bat -p --paging=never"
elif command -v batcat &> /dev/null; then
  alias cat="batcat -p --paging=never"
else
  alias cat="cat"
fi

if command -v fd &> /dev/null; then
  alias fd="fd"
elif command -v fdfind &> /dev/null; then
  alias fd="fdfind"
else
    alias fd="find"
fi

# exa is nolonger maintained, using eza instead, a maintained fork
if command -v eza &> /dev/null; then
  alias l="eza"

  # Function to wrap eza while correctly handling -l and -a flags
  _eza_wrapper() {
    local args=("$@")
    
    # If invoked as 'la', force -l -a
    if [[ "${FUNCNAME[1]}" == "la" ]]; then
      set -- -l -a "${args[@]}"
    fi

    eza --group-directories-first --icons --color=always --git -h "$@"
  }
  # Use aliases to redirect to the wrapper function
  alias ls="_eza_wrapper"
  alias la="_eza_wrapper -l -a"
  alias tree="eza --tree"
else
  alias l="ls"
  alias ls="ls --color=auto"
  alias la="ls -la --color=auto"
  alias tree="tree"
fi

# docker compose aliases
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcdu="docker compose down && docker compose up -d"
alias dcdv="docker compose down -v"
alias dcr="docker compose run --rm"
alias dcrs="docker compose down && docker compose up -d"
alias de="docker exec -it -e TERM=xterm-256color"

alias cl="clear && printf '\e[3J'"
