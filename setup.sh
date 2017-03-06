#!/usr/bin/env bash

APP_STORE_EMAIL=parkej3@gmail.com
GITHUB_EMAIL=parkej3@gmail.com
GITHUB_USER=jackp
GITHUB_SSH_TOKEN=f083c6b24c20dee0cf5f2b4d11eda0afd24169c9

# Check if command exists
function exists {
	if hash $1 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

################################################################################
# Dependency Installation
################################################################################

# Install Homebrew - https://brew.sh/
if exists brew; then
	echo "Homebrew already installed, skipping..."
else
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install Brew Bundler
brew tap Homebrew/bundle

# Install Mas for installing App Store programs
brew install mas

# Sign-in to App Store
# TODO: Suppress "already logged in" error
# TODO: Get email/password from config file
mas signin --dialog $APP_STORE_EMAIL

################################################################################
# Terminal Setup (ITerm2)
################################################################################

# Install oh-my-zsh
ZSH="$HOME/.oh-my-zsh"

if [ -d $ZSH ]; then
	echo "Oh-my-zsh already installed"
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# Copy theme file
mkdir -p $ZSH/themes
cp iterm2/gitster.zsh-theme $ZSH/themes/

################################################################################
# Google Cloud Platform Auth
################################################################################
GCLOUD_CONFIG="$HOME/.config/gcloud/application_default_credentials.json"

if [ -f $GCLOUD_CONFIG ]; then
	echo "Already authorized for Google Cloud"
else
	gcloud auth application-default login
fi

################################################################################
# Sync dotfiles
################################################################################
rsync --exclude ".git/" \
			--exclude ".DS_Store" \
			-avzP ./.[^.]* ~;

################################################################################
# Install Brew dependencies
################################################################################

if brew bundle check --global > /dev/null; then
	echo "Applications up-to-date..."
else
	echo "Installing/updating applications"
	brew bundle install --global
fi

################################################################################
# Sublime Text 3 Setup
################################################################################

# Copy settings files
cp -r sublimetext3/*.sublime-settings ~/Library/Application\ Support/Sublime\ Text*/Packages/User

# Install Package Control
cp -r sublimetext3/*.sublime-package ~/Library/Application\ Support/Sublime\ Text*/Installed\ Packages/

################################################################################
# Github SSH Key setup
################################################################################

# Generate ssh key
SSH_FILE=$HOME/.ssh/id_rsa

if [ -f $SSH_FILE ]; then
	echo "SSH key already generated."
else
	ssh-keygen -t rsa -b 4096 -C "$GITHUB_EMAIL" -f "$SSH_FILE"
fi

# Add to ssh-agent
eval "$(ssh-agent -s)" > /dev/null
ssh-add -K $SSH_FILE > /dev/null

# Upload key to Github
http -a $GITHUB_USER:$GITHUB_SSH_TOKEN \
	POST https://api.github.com/user/keys \
	title="$(scutil --get ComputerName)" \
	key="$(cat ~/.ssh/id_rsa.pub)" \
	> /dev/null
