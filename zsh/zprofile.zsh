# Builds PATH for login shells, with brew and platform directories. zshrc adds
# the user-local bins again for the non-login shells in multiplexer panes.
typeset -U path

source "$HOME/.config/zsh/source-cached.zsh"

if [[ -x /opt/homebrew/bin/brew ]]; then
    source_cached /opt/homebrew/bin/brew shellenv
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    source_cached /home/linuxbrew/.linuxbrew/bin/brew shellenv
fi

path=("$HOME/.local/nvim/bin" "$HOME/.local/bin" $path)

[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] &&
    path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")

export PATH
