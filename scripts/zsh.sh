#!/bin/bash

# We'll store plugins in a standard location
PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

# 1. Install Zsh using DNF
echo "--- Checking for Zsh installation ---"
if ! command -v zsh &>/dev/null; then
  echo "Installing Zsh..."
  sudo dnf install -y zsh
else
  echo "--> Zsh is already installed. Skipping..."
fi

# 2. Set Zsh as the default shell
# This uses the 'chsh' command to change the login shell for the current user
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  echo "--- Setting Zsh as your default shell ---"
  echo "Note: You might be prompted for your password."
  chsh -s "$ZSH_PATH"
else
  echo "--> Zsh is already your default shell."
fi

# 3. Initialize the .zshrc file
# Zsh often prompts for a 'New User' setup on first run.
# Creating a blank .zshrc prevents that annoying menu.
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
  echo "--- Creating initial .zshrc ---"
  touch "$ZSHRC"
  # Basic default settings for a better experience
  cat <<EOF >>"$ZSHRC"
# Basic Zsh Config
export LANG=en_US.UTF-8
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
EOF
else
  echo "--> .zshrc already exists."
fi

# 4. Install zsh-autosuggestions
echo "--- Setting up zsh-autosuggestions ---"
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
else
  echo "--> zsh-autosuggestions already installed. Skipping..."
fi

echo "--- Zsh Installation Complete! ---"
echo "IMPORTANT: Please LOG OUT and LOG BACK IN for the shell change to take effect."
