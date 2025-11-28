# zmodload zsh/zprof

### ────────────────────────────────
###  Powerlevel10k Setup
### ────────────────────────────────
# Pre-set SSH detection to skip expensive 'who' command in _p9k_init_ssh
typeset -gix P9K_SSH=0
typeset -gx _P9K_SSH_TTY=$TTY


### ────────────────────────────────
###  Completion System
### ────────────────────────────────
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '$HOME/.zshrc'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export CASE_SENSITIVE="true"

ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"

# Smart compinit - rebuild cache when needed, skip security check when cached
autoload -Uz compinit
if [[ ! -s $ZSH_COMPDUMP.zwc || $ZSH_COMPDUMP.zwc -ot $ZSH_COMPDUMP ]]; then
  compinit -d "$ZSH_COMPDUMP"
  zcompile "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi
autoload -U select-word-style
select-word-style bash

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end


### ────────────────────────────────
###  Zinit Plugin Manager
### ────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

setopt promptsubst

# Powerlevel10k — eager load for stable prompt
zinit ice depth=1 lucid
zinit light romkatv/powerlevel10k

# Core plugins — autosuggestions loads immediately for better UX
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions

# Other core plugins — lazy load
zinit wait lucid for \
  Aloxaf/fzf-tab \
  zsh-users/zsh-syntax-highlighting

# Completions — reload after plugin is added
zinit ice wait'1' blockf lucid atload'compinit -u'
zinit light zsh-users/zsh-completions

# Oh-My-Zsh git plugin (snippet form)
zinit ice wait'1' lucid
zinit snippet OMZP::git

# Precompile plugins once in a while (manual: `zinit compile`)
# zinit compile


### ────────────────────────────────
###  History Settings
### ────────────────────────────────
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS


### ────────────────────────────────
###  Environment / UI Settings
### ────────────────────────────────
export COLORTERM=truecolor
export PATH=$HOME/.local/nvim/bin:$PATH

if command -v fdfind >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
elif command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.*"'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"


### ────────────────────────────────
###  Optional Tools (zoxide, direnv, mise, fzf)
### ────────────────────────────────
[[ -f $HOME/.fzf.zsh ]] && source "$HOME/.fzf.zsh"
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="always"

command -v zoxide >/dev/null 2>&1 && [[ -o interactive ]] && eval "$(zoxide init --cmd cd zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"





### ────────────────────────────────
###  Google Cloud SDK Integration
### ────────────────────────────────
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"


### ────────────────────────────────
###  User Configuration Files
### ────────────────────────────────
for file in "$HOME"/.config/zsh/*.zsh; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "zshrc.zsh" ]] && continue
    source "$file"
done

[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local


### ──────────────
### Mise Config (Smart Lazy Loading)
### ──────────────
export MISE_POETRY_AUTO_INSTALL=1
export MISE_POETRY_VENV_AUTO=1

# Tool command aliases - map tool names to their commands
declare -A _mise_tool_aliases=(
    ["golang"]="go"
    ["nodejs"]="node npm npx"
    ["python"]="python python3 pip pip3"
    ["ruby"]="ruby gem"
    ["rust"]="cargo rustc"
    ["java"]="java javac"
)

# Lazy initialization function
_mise_lazy_init() {
    # Find mise binary
    local mise_bin
    if command -v /opt/homebrew/bin/mise >/dev/null 2>&1; then
        mise_bin="/opt/homebrew/bin/mise"
    elif command -v ~/.local/bin/mise >/dev/null 2>&1; then
        mise_bin="~/.local/bin/mise"
    else
        echo "mise not found" >&2
        return 1
    fi

    # Activate mise
    eval "$($mise_bin activate zsh)"

    # Remove all lazy stubs
    for _tool in "${_mise_lazy_tools[@]}" mise; do
        unset -f $_tool 2>/dev/null
    done
    unset _mise_lazy_tools _mise_tool_aliases
}

# Parse .tool-versions and create lazy stubs
if [[ -n "$DOTFILES_ROOT" && -f "$DOTFILES_ROOT/.tool-versions" ]]; then
    _mise_lazy_tools=()

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Extract tool name (first word)
        local tool_name=$(echo "$line" | awk '{print $1}')
        [[ -z "$tool_name" ]] && continue

        # Add primary tool
        _mise_lazy_tools+=($tool_name)

        # Add aliases if they exist
        if [[ -n "${_mise_tool_aliases[$tool_name]}" ]]; then
            # Split aliases by space and add them one by one
            for alias_tool in ${=_mise_tool_aliases[$tool_name]}; do
                _mise_lazy_tools+=($alias_tool)
            done
        fi
    done < "$DOTFILES_ROOT/.tool-versions"

    # Create lazy stubs for all tools + mise command itself
    for _tool in "${_mise_lazy_tools[@]}" mise; do
        eval "$_tool() { _mise_lazy_init && $_tool \"\$@\"; }"
    done

    unset _tool line tool_name aliases
fi

### ────────────────────────────────
### Final Setup
### ────────────────────────────────
fpath+=~/.zfunc

# Set blinking bar cursor - defer to avoid breaking instant prompt
if [[ $- == *i* ]]; then
  precmd_functions+=(set_cursor_shape)
  set_cursor_shape() {
    echo -ne '\033[5 q'
    precmd_functions=(${precmd_functions:#set_cursor_shape})
  }
fi

# zprof
