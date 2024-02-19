# Dotfiles Repository

This repository contains my personal dotfiles and scripts to set up a development environment on Debian-based systems. It includes configurations for Zsh (with Oh-My-Zsh), Tmux, and Neovim, along with a selection of command-line utilities like `ripgrep`, `fd-find`, `fzf`, and `bat`.

## Structure

```bash
.
├── docker-compose.yml
├── Dockerfile
├── install.sh
├── LICENSE
├── README.md
└── nvim
    ├── init.lua
    ├── lazy-lock.json
    └── lua
        ├── plugins
        │   ├── catppuccin.lua
        │   ├── neo-tree.lua
        │   ├── telescope.lua
        │   └── treesitter.lua
        └── plugins.lua
```

- `Dockerfile` and `docker-compose.yml`: For testing the installation script and trying the environment in a container.
- `install.sh`: Script to install and configure Zsh, Tmux, Neovim, and utilities.
- `nvim`: Neovim configuration files and plugins setup.

## Installation

**Warning**: The `install.sh` script will overwrite existing configurations for Zsh, Tmux, and Neovim. It is advised to backup any important configurations before proceeding.

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/dotfiles.git
   ```
2. Run the installation script with root privileges:
   ```
   cd dotfiles
   sudo ./install.sh
   ```

The installation script will perform the following actions:
- Check and install required packages (`curl`, `wget`, `git`).
- Backup existing configuration files for Zsh, Tmux, and Neovim.
- Install and configure Zsh, Tmux, Neovim, bat, ripgrep, fd-find, and fzf.
- Set correct permissions for the installed files.

## Test driving the config

Requires [Docker engine](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/).

To test drive the config all you need is to 
1) Start the container with `docker compose up -d --build`
2) Connect to the container with `docker exec -it ubuntu-dotfiles-testdrive /bin/zsh`

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
- [ ] Add starship for a fancy prompt.
- [ ] Expand neovim configuration with more plugins and customizations.
    - [ ] Add LSP support. (with Mason)
    - [ ] Add copilot support.
    - [ ] Tabs?
    - [ ] Integrated terminal?


