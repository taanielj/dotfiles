# Login shells: brew and platform PATH construction lives here. zshrc repeats
# only the user-local bins so non-login multiplexer panes get them too.
typeset -U path

if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

path=("$HOME/.local/nvim/bin" "$HOME/.local/bin" $path)

[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] &&
    path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")

export PATH
