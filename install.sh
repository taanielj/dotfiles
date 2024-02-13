#!/bin/bash
# Script to install zsh (oh-my-zsh), tmux and nvim.

# Supports only debian-based systems for now, add macOS support later if I switch to mac.

# ZSH

check_root() {
	if [ "$EUID" -ne 0 ]; then
		SUDO='sudo'
	else
		SUDO=''
	fi
}

# array of required packages
required_packages=(wget curl)

# check if required packages are installed
for package in "${required_packages[@]}"; do
	if [ ! -x "$(command -v $package)" ]; then
		echo "$package not found, installing $package"
		$SUDO apt-get install -y $package
	fi
done

# get user home (~) if not root
if [ -z "$SUDO" ]; then
	USER_HOME=$HOME
else
	USER_HOME=$(eval echo ~$(logname))
fi

update_packages() {
	if [ ! -x "$(command -v apt-get)" ]; then
		echo "apt-get not found"
		exit 1
	else
		$SUDO apt-get update
	fi

}

check_git() {
	if [ ! -x "$(command -v git)" ]; then
		echo "Git not found, installing git"
		$SUDO apt-get install -y git
	fi
}

install_zsh() {
	echo "Installing zsh"
	$SUDO apt-get install -y zsh
	# install oh-my-zsh from github
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	# get auto-suggestions
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	cp .zshrc /.zshrc
}

install_tmux() {
	echo "Installing tmux"
	$SUDO apt-get install -y tmux
	cp .tmux.conf $USER_HOME/.tmux.conf
	git clone https://github.com/tmux-plugins/tpm $USER_HOME/.tmux/plugins/tpm
	# start tmux and install plugins
	tmux start-server
	tmux new-session -d
	$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh
	tmux kill-server
}

install_nvim() {
	echo "Installing neovim"
	wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage
	# extract appimage
	chmod u+x nvim.appimage
	./nvim.appimage --appimage-extract
	# move to /usr/local/bin
	$SUDO mv ./squashfs-root /usr/local/bin/nvim
	# create symlink
	$SUDO ln -s /usr/local/bin/nvim/AppRun /usr/local/bin/nvim
	# cleanup
	rm -rf ./nvim.appimage
		
	
	mkdir -p $USER_HOME/.config/nvim
	cp -r nvim/* $USER_HOME/.config/nvim
}

check_root
update_packages
check_git
$SUDO apt-get update || {
	echo "apt-get update failed"
	exit 1
}
install_zsh
install_tmux
install_nvim

