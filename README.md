# dotfiles

My dotfiles repository with easy setup and teardown scripts.
Supports Ubuntu, Debian, termux, and macOS.
Constantly updated, no guarantees, implied or otherwise, that it will work on your system.

**Use at your own risk.**

## Quick Start

```bash
# Interactive menu: System only, All, Custom, or Teardown - pick All to install everything
bash setup.sh

# Tear down (undo) everything
bash setup.sh --teardown

# Tear down including complete cargo removal
bash setup.sh --teardown --remove-cargo
```

## What's Included

`setup.sh` runs the scripts in [setup](setup) in a fixed order (see `SETUP_SCRIPTS` at the top of the file) and offers an interactive menu to pick a subset. Each script installs and configures one component and knows how to undo itself:

- [system](setup/system.sh): base packages via apt, pkg (termux), or brew - the only script that needs sudo
- [git](setup/git.sh): sane global defaults, global ignore file, prompts for name and email, gh as credential helper when logged in
- [zsh](setup/zsh.sh): zinit, p10k, and the config under [zsh](zsh)
- [tmux](setup/tmux.sh): tpm and [tmux.conf](tmux.conf)
- [herdr](setup/herdr.sh): config and plugins for the herdr multiplexer, skipped if herdr is not installed
- [mise](setup/mise.sh): version manager for language runtimes, with an fzf picker for which to install
- [nvim](setup/nvim.sh): latest stable Neovim and the lazy.nvim config under [nvim](nvim)
- [cargo](setup/cargo.sh): Rust plus the cargo-installed CLI tools aliased in [zsh/interactive/aliases.zsh](zsh/interactive/aliases.zsh)
- [lazygit](setup/lazygit.sh): config everywhere, plus the binary itself where brew does not provide it
- [win32yank](setup/win32yank.sh): Windows clipboard tool for zsh, tmux and nvim, WSL only
- [kitty](setup/kitty.sh) and [wezterm](setup/wezterm.sh): terminal emulators installed as casks, macOS only
- [karabiner](setup/karabiner.sh): [karabiner.json](karabiner/karabiner.json) for Karabiner-Elements, macOS only

The [Dockerfile](Dockerfile) and [compose.yaml](compose.yaml) build a throwaway Debian container to try the setup in:

```bash
docker compose up -d --build
docker compose exec ubuntu-dev bash
```

## Teardown

You can use `bash setup.sh --teardown` to undo all the configuration:

- Restores original configs if they were backed up
- Removes all symlinks created by the setup scripts
- Uninstalls tools installed by the setup scripts where appropriate
- Executes teardown functions in reverse order of setup
- Use `--remove-cargo` flag to completely remove cargo installation (not just the tools)

Note that `system.sh` packages are not removed, as they may be used by other applications. You can check what packages it installs at the top of the script.
