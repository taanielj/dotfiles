# dotfiles

My dotfiles repository with easy setup and teardown scripts.
Supports Ubuntu, Debian, termux, and macOS.
**Use at your own risk.** Constantly updated, with no guarantee that it works on your system.

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

`setup.sh` runs the scripts in [setup](setup) in the order of `SETUP_SCRIPTS` at the top of the file. An interactive menu picks a subset instead.

Each script installs and configures one component and knows how to undo itself:

- [system](setup/system.sh): base packages via apt, pkg (termux), or brew - the only script that needs sudo
- [git](setup/git.sh): global git config
  - Sets global defaults for keys that are still unset.
  - Installs a global ignore file.
  - Prompts for name and email.
  - Sets gh as credential helper when gh is logged in.
- [zsh](setup/zsh.sh): zinit, p10k (or starship with `ZSH_PROMPT=starship` in ~/.zshrc.local), and the config under [zsh](zsh)
- [tmux](setup/tmux.sh): tpm and [tmux.conf](tmux.conf)
- [herdr](setup/herdr.sh): the herdr multiplexer and its [config and plugins](herdr/tui)
  - On macOS, brew installs the herdr binary.
  - On macOS, the script also installs the Herdr desktop app and herdr-core, and links the app's [settings, keys, theme and mods](herdr/app) into `~/.config/herdr-app`.
  - The [scripts that both herdr and the Herdr app run](herdr/bin) are linked onto PATH.
  - [herdr-sync](herdr/bin/herdr-sync.sh) rebuilds one side's workspaces, tabs and splits from the other's, moving nvim and Claude sessions across: `prefix Y` in herdr, `cmd-space Y` in the Herdr app.
- [mise](setup/mise.sh): version manager for language runtimes, with an fzf picker for which to install
- [nvim](setup/nvim.sh): latest stable Neovim and the lazy.nvim config under [nvim](nvim)
- [cargo](setup/cargo.sh): Rust plus the cargo-installed CLI tools aliased in [zsh/interactive/aliases.zsh](zsh/interactive/aliases.zsh)
- [lazygit](setup/lazygit.sh): config everywhere, plus the binary itself where brew does not provide it
- [bat](setup/bat.sh): [config](bat) with a vendored Catppuccin theme and a JSON log syntax. The script also builds bat's theme and syntax cache
- [clipboard](setup/clipboard.sh): pbcopy and pbpaste shims for zsh, tmux and scripts, Linux and WSL only. On WSL, the script also installs a wslview that nvim uses to open links and files.
- [win32yank](setup/win32yank.sh): Windows clipboard tool behind the shims and nvim, WSL only
- [superfile](setup/superfile.sh): the superfile file manager from its release tarball, Linux only. On macOS, brew installs superfile.
- [kitty](setup/kitty.sh), [ghostty](setup/ghostty.sh) and [wezterm](setup/wezterm.sh): terminal emulators installed as casks, macOS only
- [karabiner](setup/karabiner.sh): [karabiner.json](karabiner/karabiner.json) for Karabiner-Elements, macOS only
- [hammerspoon](setup/hammerspoon.sh): [init.lua](hammerspoon/init.lua) for Hammerspoon, macOS only
  - cmd+hjkl moves window focus.
  - alt+hjkl resizes windows.
  - At the edge of their own layout, herdr, the Herdr app and nvim focus and resize macOS windows through Hammerspoon.

The [Dockerfile](Dockerfile) and [compose.yaml](compose.yaml) build a throwaway Debian container to try the setup in:

```bash
docker compose up -d --build
docker compose exec ubuntu-dev bash
```

## Teardown

`bash setup.sh --teardown` runs the teardown functions in reverse order of setup. Each teardown function:

- Restores the original configs that were backed up.
- Removes the symlinks the setup scripts created.
- Uninstalls the tools the setup scripts installed.

`--remove-cargo` also removes the cargo installation itself. Without it, the script removes only the cargo-installed tools.

Teardown leaves the `system.sh` packages installed because other applications may use them. The package lists are at the top of the script.
