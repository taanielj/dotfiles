# dotfiles

My dotfiles repository with easy setup and teardown scripts.
Supports Ubuntu, termux, and macOS, possibly debian.
Constantly updated, no guarantees, implied or otherwise, that it will work on your system.

**Use at your own risk.**

## Quick Start

```bash
# Install everything
bash setup.sh

# Tear down (undo) everything
bash tear-down.sh

# Tear down including complete cargo removal
bash tear-down.sh --remove-cargo
```

## What's Included

Run `bash setup.sh` to setup:

- [system packages](setup/system.sh): installs various packages using apt (Ubuntu/Debian), pkg (termux), or brew (macOS)
  - the basics, such as git, curl, wget, various build tools, if they're not already installed
- [zsh](setup/zsh.sh): uses zinit, p10k, various plugins, see [zsh/zshrc](zsh/zshrc)
- [neovim](setup/nvim.sh) uses lazy.nvim, various plugins see [plugins dir](nvim/lua/plugins)
- [tmux](setup/tmux.sh): uses tpm, various plugins, see [tmux.conf](tmux.conf)
- Also have [setup scripts](setup) for setting up:
  - [mise.sh](setup/mise.sh) - A modern alternative to asdf [mise.sh](setup/mise.sh)
    - Choose whether to install nodejs, python, java, go, ruby etc (fzf, use tab to toggle)
  - [cargo.sh](setup/cargo.sh) - Rust package manager [cargo.sh](setup/cargo.sh), also installs:
    - eza - A modern alternative to ls, aliased to `ls`
    - zoxide - A smarter cd, aliased to `cd`
    - bat - a pretty cat, aliased to `cat`
    - ripgrep - faster grep, run with `rg`
    - fd-find - a simpler, faster, smarter find, run with `fd`
  - [lazygit](setup/lazygit.sh) - A Terminal User Interface (TUI) for git commands, run with `lazygit`
  - [kitty.sh](setup/kitty.sh) - A fast, feature-rich, GPU based terminal emulator, run with `kitty` MacOS only currently, since I use linux via WSL most of the time

That list is up to date as of Sep 02, 2025. If you see later commit dates, that means I updated something but didn't update this list.

## Teardown

You can use `tear-down.sh` to undo all the configuration:

- Restores original configs if they were backed up
- Removes all symlinks created by the setup scripts
- Uninstalls tools installed by the setup scripts where appropriate
- Executes teardown functions in reverse order of setup
- Use `--remove-cargo` flag to completely remove cargo installation (not just the tools)

Note that `system.sh` packages are not removed, as they may be used by other applications. You can check what packages it installs at the top of the script.
