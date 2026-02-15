#!/bin/bash

# Stow the config from the dotfiles repo
cd ~/dotfiles
stow starship

# 1. Install Zsh and Starship Binary
echo "--- Installing Zsh and Starship ---"
# Fedora uses dnf; we ensure zsh is installed first
sudo dnf install -y zsh

# Install Starship via the official cross-shell script
curl -sS https://starship.rs/install.sh | sh

# 2. Set Zsh as Default Shell
# This will prompt for your password once
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "--- Setting Zsh as your default shell ---"
  chsh -s $(which zsh)
fi

# 3. Create Starship Config Directory
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"

# 4. Create a basic starship.toml (if it doesn't exist)
if [ ! -f "$CONFIG_DIR/starship.toml" ]; then
  echo "--- Creating starship.toml config ---"
  cat <<EOF >"$CONFIG_DIR/starship.toml"
add_newline = true

[character]
success_symbol = '[➜](bold green)'
error_symbol = '[➜](bold red)'

# Custom for your Go development
[golang]
symbol = " "
format = 'via [$symbol($version )]($style)'
EOF
fi

# 5. Add Starship to .zshrc (Idempotent check)
ZSHRC="$HOME/.zshrc"
INIT_LINE='eval "$(starship init zsh)"'

# Create .zshrc if it doesn't exist
touch "$ZSHRC"

if ! grep -Fxq "$INIT_LINE" "$ZSHRC"; then
  echo "--- Adding Starship to .zshrc ---"
  echo "" >>"$ZSHRC"
  echo "# Starship Prompt" >>"$ZSHRC"
  echo "$INIT_LINE" >>"$ZSHRC"
else
  echo "--> Starship init already present in .zshrc. Skipping..."
fi

echo "--- Setup Complete! ---"
echo "Please log out and log back in (or restart) for the shell change to take effect."
echo "Then, open your terminal and enjoy Zsh + Starship!"
