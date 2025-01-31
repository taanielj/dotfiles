# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

export PATH="$PATH:/snap/bin"
### End of lines added by compinstall

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh configuration

## Theme configuration
# ZSH_THEME="robbyrussell"
# Powerlevel10k configuration
ZSH_THEME="powerlevel10k/powerlevel10k"

## Plugin configuration
plugins=(
  git
  zsh-autosuggestions
)



## Autocomplete configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

## Update configuration
zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13

## Source the Oh My Zsh script
source $ZSH/oh-my-zsh.sh

# Environment configuration

## Enable true color support - needed for tmux and nvim
export COLORTERM=truecolor

# Key bindings configuration

## ctrl up and down do nothing
bindkey -s "^[[1;5A" ""
bindkey -s "^[[1;5B" ""

## ctrl left and right: move to left or right word (these don't work on mac)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## option left and right: move to left or right word (these work on mac)
## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^H" backward-kill-word # ctrl backspace
bindkey "^[[3;5~" kill-word # ctrl delete

# Aliases configuration
alias vim=nvim
# on mac, the command is bat, on linux, it's batcat
# alias cat="batcat -p --paging=never"
# check if bat command exists, if not use batcat, if not use cat
if command -v bat &> /dev/null; then
  alias cat="bat -p --paging=never"
elif command -v batcat &> /dev/null; then
  alias cat="batcat -p --paging=never"
else
  alias cat="cat"
fi
#on mac the command is fd, on linux, it's fdfind
#alias fd="fdfind"
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

    eza --git-ignore --group-directories-first --icons --color=always --git -h "$@"
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


# Custom functions

# Initialize zoxide
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
export FZF_DEFAULT_COMMAND='fd --hidden'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#alias nvimf="fd --type f --hidden | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}' | xargs nvim"
nvimf() {
    if [[ "$1" != "" && -d -$1 ]];
    then
        nvim $(fd . $1 | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')]
    else
        nvim $(fd --type f --hidden | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')
    fi
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# set alias for python=python3.11
# alias python=python3.11

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc'; fi


__check_python_env() {
    # Set preferred Python version/command
    declare -a python_versions=(
        "python3.12"
        "python3.11"
        "python3.10"
        "python3.9"
        "python3.8"
        "python3.7"
        "python3.6"
        "python3"
        "python"
    )

    for version in "${python_versions[@]}"; do
        if command -v "$version" &>/dev/null; then
            PYTHON_EXEC="$version"
            break
        fi
    done

    if [[ -z "$PYTHON_EXEC" ]]; then
        echo "No Python executable found. Please install Python."
        return 1
    else
        export PYTHON_EXEC
    fi

    # Check for pip
    if ! $PYTHON_EXEC -m pip -V &>/dev/null; then
        echo "pip not found. Installing pip..."
        if ! $PYTHON_EXEC -m ensurepip &>/dev/null; then
            echo "Failed to install pip. Please install pip manually."
            return 1
        fi
        $PYTHON_EXEC -m pip install --upgrade pip
    fi

    # Check for venv
    if $PYTHON_EXEC -m venv --help &>/dev/null; then
        export VENV_MODULE="venv"
    elif $PYTHON_EXEC -m virtualenv --help &>/dev/null; then
        export VENV_MODULE="virtualenv"
    else
        echo "Warning: venv or virtualenv not found. Installing virtualenv..."
        if ! $PYTHON_EXEC -m pip install virtualenv &>/dev/null; then
            echo "Failed to install virtualenv. Please install a virtual environment manager manually."
            return 1
        fi
    fi
}

__resolve_venv_path() {
    local venv_dir="${1:-$VIRTUAL_ENV}"

    # If no explicit name or $VIRTUAL_ENV is not set, try to find a common venv directory
    if [[ -z "$venv_dir" ]]; then
        for dir in ".venv" "venv" "env"; do
            if [[ -d "$dir" ]]; then
                venv_dir="$dir"
                break
            fi
        done
    fi

    venv_dir="${venv_dir:-.venv}"  # Default to .venv if nothing found

    # If the path is already absolute, return it
    if [[ "$venv_dir" == /* ]]; then
        echo "$venv_dir"
        return
    fi

    # If the directory exists, get its absolute path
    if [[ -d "$venv_dir" ]]; then
        (cd "$venv_dir" && pwd)
    else
        # If the directory doesn't exist, construct the absolute path manually
        echo "$(pwd)/$venv_dir"
    fi
}

__confirm_action() {
    local prompt="$1"
    echo "$prompt (y/n)"
    read -r input
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    [[ "$input" == "y" ]]
}

__require_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "Not in a virtual environment. Run 'venv' to create one or activate an existing one."
        return 1
    fi
}

__require_reqs() {
    if [[ ! -f "requirements.txt" || ! -s "requirements.txt" ]]; then
        echo "No requirements.txt file found or empty."
        return 1
    fi
}

venv() {
    if [[ -n "$VIRTUAL_ENV" && -x "$VIRTUAL_ENV/bin/python" ]]; then        
        echo "Virtual environment already activated: $VIRTUAL_ENV"
        echo "Options: rm_venv to remove, reset_venv to recreate, deactivate to close venv."
        return
    fi

    __check_python_env || return 1

    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    # Activate existing virtual environment if found
    if [[ -d "$venv_path" ]]; then
        source "$venv_path/bin/activate"
        echo "Virtual environment activated: $VIRTUAL_ENV"
        return
    fi

    echo "Creating a new virtual environment in $venv_path..."
    $PYTHON_EXEC -m $VENV_MODULE "$venv_path"
    source "$venv_path/bin/activate"
    python -m pip install --upgrade pip
    echo "Virtual environment created and activated: $VIRTUAL_ENV"
    
    if __require_reqs &>/dev/null; then
        if __confirm_action "Would you like to install the requirements?"; then
            reqs
        fi
    fi
}

rm_venv() {
    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
        echo "No virtual environment found."
        return
    fi

    if ! __confirm_action "Are you sure you want to remove the virtual environment at '$venv_path'?"; then
        return
    fi

    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$venv_path" ]] && deactivate
    rm -rf "$venv_path"
    echo "Virtual environment removed: $venv_path"
}



reset_venv() {
    local venv_path
    venv_path=$(__resolve_venv_path "$1")

    if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
        echo "No virtual environment found to reset."
        return
    fi

    if ! __confirm_action "Are you sure you want to reset the virtual environment at '$venv_path'?"; then
        return
    fi

    [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$venv_path" ]] && deactivate
    rm -rf "$venv_path"
    venv "$venv_path"
}

reqs() {
    __require_reqs || return 1
    __require_venv || return 1
    pip install --upgrade -r requirements.txt
    echo "Requirements installed, run 'update_reqs' to update to latest and freeze versions."
}

update_reqs() {
    __require_reqs || return 1
    __require_venv || return 1
    if ! __confirm_action "This will update all packages to latest and freeze versions. Continue?"; then
        return
    fi

    # Step 1: Strip version numbers from requirements.txt in-place
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/==.*//g' requirements.txt
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sed -i 's/==.*//g' requirements.txt
    fi

    # Step 2: Install all packages from requirements.txt
    python -m pip install --upgrade -r requirements.txt

    # Step 3: Get the installed package versions from pip freeze
    frozen_reqs=$(pip freeze)

    # Step 4: Add version numbers back in-place, preserving comments and blank lines
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            # Preserve empty lines and comments as is
            echo "$line"
        else
            base_req=$(echo "$line" | sed 's/\[.*\]//')  # Strip extras to match pip freeze
            # Perform a case-insensitive match against pip freeze
            frozen_line=$(echo "$frozen_reqs" | grep -i -m 1 "^${base_req}==")
            if [[ -n $frozen_line ]]; then
                # Append the version to the existing line
                echo "${line}==${frozen_line##*==}"  # Extract and append version
            else
                # If no version is found, keep the line unchanged
                echo "$line"
            fi
        fi
    done < requirements.txt > requirements.tmp

    # Replace the old requirements.txt with the updated file
    mv requirements.tmp requirements.txt
}

# docker compose aliases
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcdv="docker compose down -v"
alias dcr="docker compose run --rm"
alias dcrs="docker compose down && docker compose up -d"



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
