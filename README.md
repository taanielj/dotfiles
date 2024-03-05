# Dotfiles Repository

This repository contains my personal dotfiles and scripts to set up a development environment on Debian-based systems. It includes configurations for Zsh (with Oh-My-Zsh), Tmux, and Neovim, along with a selection of command-line utilities like `ripgrep`, `fd-find`, `fzf`, and `bat`.

## Structure

```bash
.
├── .tmux.conf
├── .zshrc
├── docker-compose.yml
├── Dockerfile
├── install.sh
├── LICENSE
├── README.md
└── .config/nvim
    ├── init.lua
    └── lua
        ├── plugins
        │   ├── alpha.lua       # Dashboard
        │   ├── barbar.lua      # Tabline
        │   ├── catppuccin.lua  # Theme
        │   ├── completions.lua # Autocomplete
        │   ├── copilot.lua     # Autocomplete on steroids
        │   ├── gitsigns.lua    # For previewing git changes
        │   ├── lsp-config.lua  # Language Server Protocol configuration
        │   ├── lualine.lua     # Statusline
        │   ├── neo-tree.lua    # File navigation
        │   ├── none-ls.lua     # Add linter support for lsp (null-ls drop in replacement)
        │   ├── telescope.lua   # Fuzzy searching and navigation
        │   ├── treesitter.lua  # Syntax highlighting
        │   └── which-key.lua   # Cheat sheet for keybindings
        └── vim-options.lua     # Neovim options and general keybindings
```

- `Dockerfile` and `docker-compose.yml`: For testing the installation script and trying the environment in a container.
- `install.sh`: Script to install and configure Zsh, Tmux, Neovim, and utilities.
- `./config/nvim`: Neovim configuration files and plugins setup.

## Installation

**Warning**: The `install.sh` script will overwrite existing configurations for Zsh, Tmux, and Neovim. Existing files are backed up to `~/config-backup` before the installation. fh
1. Clone this repository:
   ```
   git clone https://github.com/yourusername/dotfiles.git
   ```
2. Run the installation script with root privileges:
   ```
   cd dotfiles
   sudo ./install.sh
   ```

The installation script will perform  the following actions:
- Check and install required packages 
  - `curl`, `wget` - for downloading files
  - `cmake`, `gcc`, `g++`, `make` - used by rustup and some nvim plugins
  - `zsh`, `tmux` - the main shell and terminal multiplexer
  - `neovim` - custom installation from the official repository using v0.9.5 appimage, extracted to /opt/nvim and symlinked to /usr/local/bin/nvim
  - `bat` - a cat clone with syntax highlighting, line numbers and git integration
  - `ripgrep` - a faster grep
  - `fd-find` - a better, faster and more user-friendly find
  - `fzf` - a general-purpose command-line fuzzy finder
- Backup existing configuration files for Zsh, Tmux, and Neovim.

## Neovim info

### Currently installed language servers (LSPs)
The Neovim is configured to use the following language servers:
- `lua_ls` - Lua language server
- `pyright` - Python language server
- `dockerls` - Dockerfile language server
- `terraformls` - Terraform language server

### Linters:
- For linting Neovim is configured to use none-ls (fork of null-ls) and will auto install stylua, prettier and black for lua, javascript and python respectively.
- It will attempt to auto detect other linters and install them as well based on the open buffers.

## Test driving the config

Requires [Docker engine](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/).

To test drive the config all you need is to 
1) Start the container with `docker compose up -d --build`
2) Connect to the container with `docker exec -it ubuntu-dev /bin/zsh`

## Custom Neovim Configuration

The Neovim setup includes an `init.lua` configuration and several Lua-based plugins for an enhanced coding experience. The plugins are managed through a custom `plugins.lua` file and include themes (catppuccin), file navigation (neo-tree), fuzzy searching (telescope), and syntax highlighting (treesitter).

## License

This project is open-sourced under the [MIT License](LICENSE). Feel free to fork, modify, and use it in your own setups.

## Acknowledgments

Thanks to the authors and contributors of the following projects:

- Oh My Zsh: https://ohmyz.sh/
- Tmux Plugin Manager: https://github.com/tmux-plugins/tpm
- Neovim: https://neovim.io/

## TODO

- [ ] Add support for other Linux distributions.
- [ ] Add support for macOS.
- [x] Add starship for a fancy prompt - actually added powerlevel10k
- [ ] Expand neovim configuration with more plugins and customizations.
    - [x] Add LSP support. (with Mason) - done, also added none-ls for linter support
    - [x] Add copilot support. - done, with nvim-cmp integration
    - [x] Tabs - done, added barbar
    - [ ] Integrated terminal?


