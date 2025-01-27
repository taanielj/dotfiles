#!/usr/bin/env bash
# Unified installation script for Ubuntu/Debian/MacOS/Termux
# Do not run with sudo - script will invoke it when needed

# set -e  # Exit on error

# Detect OS
detect_os() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
		ubuntu)
			echo "ubuntu"
			return
			;;
		debian)
			echo "debian"
			return
			;;
		esac
	elif [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
		echo "termux"
		return
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		echo "macos"
		return
	fi
	echo "unsupported"
}

# Check if running with sudo
check_sudo() {
	if [ "$(id -u)" -eq 0 ]; then
		if [ -z "$SUDO_USER" ]; then
			echo "Running as root, continuing..."
			return 0
		else
			echo "This script should not be run with sudo. Please run as normal user."
			exit 1
		fi
	fi
}

need_sudo() {
	if [ "$(id -u)" -eq 0 ]; then
		return 1 # root doesn't need sudo
	else
		return 0 # non-root needs sudo
	fi
}

:/#!/usr/bin/env bash

# Define packages that should be installed across all environments
PACKAGES=(
	"curl"
	"wget"
	"git"
	"cmake"
	"gcc"
	"g++"
	"zsh"
	"tmux"
	"python3.11"
	"bat"
	"ripgrep"
	"fd-find"
	"fzf"
	"eza"
	"zoxide"
	"node"
	"nvim"
	"lazygit"
	"fastfetch"
)

# Define custom installation methods for specific packages per OS
declare -A CUSTOM_INSTALL
CUSTOM_INSTALL["ubuntu:python3.11"]="add-apt-repository -y ppa:deadsnakes/ppa && apt install -y python3.11"
CUSTOM_INSTALL["ubuntu:eza"]="mkdir -p /etc/apt/keyrings && \
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/eza.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main' | tee /etc/apt/sources.list.d/eza.list && \
    apt update && apt install -y eza"
CUSTOM_INSTALL["ubuntu:nvim"]="wget https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -O /usr/local/bin/nvim && \
    chmod +x /usr/local/bin/nvim"
CUSTOM_INSTALL["ubuntu:node"]="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"

# Repository directory
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Display initial warning
display_warning() {
	echo "This script will install and configure:"
	echo "- Shell: Zsh with Oh-My-Zsh and Powerlevel10k"
	echo "- Terminal multiplexer: Tmux with plugins"
	echo "- Editor: Neovim with custom config"
	echo "- Modern CLI tools: bat, ripgrep, fd, fzf, eza, zoxide"
	echo "- Development tools: Python, Node.js, Git"
	echo
	echo "It will backup existing configurations to ~/config-backup-<timestamp>"
	echo
	if [ "$1" = "debian" ]; then
		echo "WARNING: Running on Debian. Some features might not work as expected."
		echo
	fi
	read -p "Press Enter to continue or Ctrl+C to cancel..."
}
# Package management functions
install_brew() {
	if ! command -v brew &>/dev/null; then
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		# Add brew to PATH for current session
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi
}

get_basic_requirements() {
	local os=$1
	for req in "${BASIC_REQUIREMENTS[@]}"; do
		if [[ $req == ${os}:* ]]; then
			echo "${req#*:}"
			return 0
		fi
	done
	return 1
}

install_basic_requirements() {
	local os=$1
	local requirements=$(get_basic_requirements "$os")

	if [ -n "$requirements" ]; then
		echo "Installing basic requirements for $os..."
		case $os in
		ubuntu | debian)
			if need_sudo; then
				sudo apt-get update -qq
				sudo apt-get install -qq -y $requirements
			else
				apt-get update -qq
				apt-get install -qq -y $requirements
			fi
			;;
		esac
	fi
}

get_package_info() {
	local package=$1
	local os=$2
	for p in "${INSTALLATIONS[@]}"; do
		if [[ $p == ${package}:* ]]; then
			echo "$p" | tr ':' '\n' | grep "^${os}|" | cut -d'|' -f2,3
			return 0
		fi
	done
	return 1
}

install_basic_requirements() {
	local os=$1
	local requirements=$(get_basic_requirements "$os")

	if [ -n "$requirements" ]; then
		echo "Installing basic requirements for $os..."
		case $os in
		ubuntu | debian)
			if need_sudo; then
				sudo apt-get update -qq
				sudo apt-get install -qq -y $requirements
			else
				apt-get update -qq
				apt-get install -qq -y $requirements
			fi
			;;
		esac
	fi
}

setup_package_manager() {
	local os=$1
	case $os in
	ubuntu | debian)
		if need_sudo; then
			sudo apt-get update -qq
		else
			apt-get update -qq
		fi
		;;
	macos)
		install_brew
		brew update
		;;
	termux)
		pkg update -y
		;;
	esac
}

install_package() {
	local os=$1
	local package=$2

	echo "Installing $package..."

	# Check if package has a custom installation method
	local custom_key="${os}:${package}"
	if [ -n "${CUSTOM_INSTALL[$custom_key]}" ]; then
		if need_sudo; then
			sudo bash -c "${CUSTOM_INSTALL[$custom_key]}"
		else
			bash -c "${CUSTOM_INSTALL[$custom_key]}"
		fi
		return
	fi

	# Default installation method based on OS
	case $os in
	ubuntu | debian)
		if need_sudo; then
			sudo apt-get install -y "$package"
		else
			apt-get install -y "$package"
		fi
		;;
	macos)
		brew install "$package"
		;;
	termux)
		pkg install -y "$package"
		;;
	esac
}

backup_config() {
	local config_backup_dir="$HOME/config-backup-$(date +%Y%m%d%H%M%S)"

	# Define arrays for config names and paths separately
	CONFIG_NAMES=(
		"oh-my-zsh"
		"zshrc"
		"p10k.zsh"
		"tmux.conf"
		"tmux"
		"nvim"
		"gitignore_global"
	)

	CONFIG_PATHS=(
		"$HOME/.oh-my-zsh"
		"$HOME/.zshrc"
		"$HOME/.p10k.zsh"
		"$HOME/.tmux.conf"
		"$HOME/.tmux"
		"$HOME/.config/nvim"
		"$HOME/.gitignore_global"
	)

	local config_exists=false
	for path in "${CONFIG_PATHS[@]}"; do
		if [ -e "$path" ] && [ ! -L "$path" ]; then
			config_exists=true
			break
		fi
	done

	if [ "$config_exists" = true ]; then
		echo "Creating backup directory: $config_backup_dir"
		mkdir -p "$config_backup_dir"

		local i=0
		while [ $i -lt ${#CONFIG_PATHS[@]} ]; do
			local path="${CONFIG_PATHS[$i]}"
			local name="${CONFIG_NAMES[$i]}"
			if [ -e "$path" ] && [ ! -L "$path" ]; then
				echo "Backing up existing $name configuration..."
				cp -r "$path" "$config_backup_dir/"
				rm -rf "$path"
			fi
			i=$((i + 1))
		done
	fi
}

configure_zsh() {
	echo "Configuring Zsh..."
	if ! command -v zsh &>/dev/null; then
		echo "Zsh is not installed. Installation failed."
		return 1
	fi

	# Remove existing oh-my-zsh if present
	rm -rf "$HOME/.oh-my-zsh"

	# Install oh-my-zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

	# Install plugins and theme
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

	# Create symlinks
	ln -sf "$repo_dir/zshrc" "$HOME/.zshrc"
	ln -sf "$repo_dir/p10k.zsh" "$HOME/.p10k.zsh"
}

configure_tmux() {
	echo "Configuring tmux..."
	if ! command -v tmux &>/dev/null; then
		echo "Tmux is not installed. Installation failed."
		return 1
	fi

	# Install TPM
	git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	ln -sf "$repo_dir/tmux.conf" "$HOME/.tmux.conf"

	# Install plugins
	tmux start-server
	tmux new-session -d
	"$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
	tmux kill-server
}

configure_nvim() {
	echo "Configuring Neovim..."
	if ! command -v nvim &>/dev/null; then
		echo "Neovim is not installed. Installation failed."
		return 1
	fi

	mkdir -p "$HOME/.config"
	ln -sf "$repo_dir/nvim" "$HOME/.config/nvim"
}

setup_git() {
	echo "Configuring Git..."

	# Add global gitignore
	ln -sf "$repo_dir/gitignore_global" "$HOME/.gitignore_global"
	git config --global core.excludesfile ~/.gitignore_global

	# Check existing git config
	local git_user_name=$(git config --global user.name)
	local git_email=$(git config --global user.email)

	if [ -z "$git_user_name" ] || [ -z "$git_email" ]; then
		echo "Git user not configured."
		read -p "Enter your git user name: " git_user_name
		read -p "Enter your git email: " git_email
		git config --global user.name "$git_user_name"
		git config --global user.email "$git_email"
	else
		echo "Git already configured for user: $git_user_name"
	fi
}

install_packages() {
	local os=$1

	for package in "${PACKAGES[@]}"; do
		install_package "$os" "$package"
	done
}

setup_macos() {
	# Install additional packages for MacOS and their configurations
	# kitty terminal
	brew install kitty
	ln -sf "$repo_dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"

	# karabiner-elements
	# symlink karabiner dir to config
	ln -s "$repo_dir/karabiner" "$HOME/.config/karabiner"
	brew install --cask karabiner-elements
}

main() {
	# Check if running with sudo
	check_sudo

	# Detect OS
	local os=$(detect_os)
	if [ "$os" = "unsupported" ]; then
		echo "Unsupported operating system"
		exit 1
	fi

	# Display warning and get confirmation
	display_warning "$os"

	# Setup package manager and install basic requirements
	setup_package_manager "$os"
	install_basic_requirements "$os"

	# Backup existing configurations
	backup_config

	# Install all required packages
	install_packages "$os"

	# Configure everything
	configure_zsh
	configure_tmux
	configure_nvim
	setup_git
	if [ "$os" = "macos" ]; then
		setup_macos
	fi

	echo "Installation completed successfully!"
	echo "Please restart your terminal and run 'zsh' to complete the setup."
}

# Run main function
main
