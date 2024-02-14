#!/bin/bash
# Script to install zsh (oh-my-zsh), tmux and nvim.

# Supports only debian-based systems for now, add macOS support later if I switch to mac.

# ZSH

required_packages=(sudo apt-get curl wget git)

check_root() {
	if [ "$EUID" -ne 0 ]; then
		SUDO='sudo'
	else
		SUDO=''
	fi
}

check_required_packages() {
	# checks if required packages are installed, provides entire list of missing packages and only then exits
	missing_packages=()
	for package in "${required_packages[@]}"; do
		if [ ! -x "$(command -v $package)" ]; then
			missing_packages+=($package)
		fi
	done
	if [ ${#missing_packages[@]} -ne 0 ]; then
		echo "Missing required packages: ${missing_packages[@]}"
		exit 1
	fi
}




# get user home (~) if not root
if [ -z "$SUDO" ]; then
	USER_HOME=$HOME
else
	USER_HOME=$(eval echo ~$(logname))
fi

# get name of the user





install_zsh() {
	echo "Installing zsh"
	$SUDO apt-get install -y zsh
	# install oh-my-zsh from github
	rm -rf $USER_HOME/.oh-my-zsh
	sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	# set zsh as default shell
	# get auto-suggestions
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	cp .zshrc $USER_HOME/.zshrc
}

install_tmux() {
	echo "Installing tmux"
	$SUDO apt-get install -y tmux
	git clone https://github.com/tmux-plugins/tpm $USER_HOME/.tmux/plugins/tpm
	cp .tmux.conf $USER_HOME/.tmux.conf
	# start tmux and install plugins
	tmux start-server
	tmux new-session -d
	$USER_HOME/.tmux/plugins/tpm/scripts/install_plugins.sh
	tmux kill-server
}

install_nvim() {
	echo "Installing neovim"
	wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage
	# extract appimage
	chmod u+x nvim.appimage
	./nvim.appimage --appimage-extract
	
	$SUDO mv ./squashfs-root /opt/nvim
	# create symlink

	$SUDO ln -s /opt/nvim/AppRun /usr/bin/nvim

	# cleanup
	rm -rf ./nvim.appimage
		
	
	mkdir -p $USER_HOME/.config/nvim
	cp -r nvim/* $USER_HOME/.config/nvim
}

check_root
check_required_packages
$SUDO apt-get update || {
	echo "apt-get update failed"
	exit 1
}
install_zsh
install_tmux
install_nvim

