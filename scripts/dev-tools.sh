#!/bin/bash

# General development tools setup script
# This script installs development tools that are not distro-specific

# Function to stow dotfiles configuration
stow_config() {
  echo "Stowing dotfiles config..."
  cd ~/dotfiles
  stow nvim tmux
}

# Function to install Homebrew
install_homebrew() {
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Function to install Homebrew packages
install_homebrew_pkgs() {
  echo "Installing Homebrew packages..."
  brew install jesseduffield/lazydocker/lazydocker
  brew install lazygit
}

# Function to install uv package manager
install_uv() {
  echo "Installing uv package manager..."
  curl -LsSf https://astral.sh/uv/install.sh | sh

  echo "Installing Ruff Python Linter..."
  uv tool install ruff@latest
}

# Function to setup GitHub SSH key
setup_ssh() {
  echo "Setting up GitHub SSH key..."
  if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists. Skipping generation."
  else
    read -p "Enter your email for the SSH key: " email
    ssh-keygen -t ed25519 -C "$email"
  fi
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  echo "SSH public key:"
  cat ~/.ssh/id_ed25519.pub
}

# Function to clone repositories
clone_repos() {
  echo "Cloning dotfiles..."
  cd ~
  if [ -d ~/dotfiles ]; then
    echo "Dotfiles directory already exists. Skipping clone."
  else
    git clone git@github.com:ropali/dotfiles.git
  fi

  echo "Cloning wallpapers..."
  mkdir -p ~/Pictures
  cd ~/Pictures
  if [ -d ~/Pictures/wallpapers ]; then
    echo "Wallpapers directory already exists. Skipping clone."
  else
    git clone git@github.com:FrenzyExists/wallpapers.git
  fi

  # Install TPM (Tmux Plugin Manager)
  if [ -d ~/.tmux/plugins/tpm ]; then
    echo "TPM already installed. Skipping."
  else
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

# Function to install Rust
install_rust() {
  echo "Installing Rust..."
  if command -v rustc >/dev/null 2>&1; then
    echo "Rust is already installed. Skipping."
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  fi
}

# Function to install NVM and Node.js
install_nvm_nodejs() {
  echo "Installing NVM..."
  # Download and install nvm:
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

  # in lieu of restarting the shell
  \. "$HOME/.nvm/nvm.sh"

  # Download and install Node.js:
  nvm install 24

  # Verify the Node.js version:
  node -v # Should print "v24.13.1".

  # Verify npm version:
  npm -v # Should print "11.8.0".
}

# Function to run other setup scripts in the same folder
run_other_setups() {
  echo "Running other setup scripts..."
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [ -f "$script_dir/nerdfonts.sh" ]; then
    bash "$script_dir/nerdfonts.sh"
  else
    echo "nerdfonts.sh not found, skipping."
  fi

  if [ -f "$script_dir/zsh.sh" ]; then
    bash "$script_dir/zsh.sh"
  else
    echo "zsh.sh not found, skipping."
  fi

  if [ -f "$script_dir/starship.sh" ]; then
    bash "$script_dir/starship.sh"
  else
    echo "starship.sh not found, skipping."
  fi

  if [ -f "$script_dir/docker.sh" ]; then
    bash "$script_dir/docker.sh"
  else
    echo "docker.sh not found, skipping."
  fi

  if [ -f "$script_dir/setup_android.sh" ]; then
    bash "$script_dir/setup_android.sh"
  else
    echo "setup_android.sh not found, skipping."
  fi

  if [ -f "$script_dir/flutter.sh" ]; then
    bash "$script_dir/flutter.sh"
  else
    echo "flutter.sh not found, skipping."
  fi
}

# Main function to run all development tool setups
main() {
  stow_config
  install_homebrew
  install_homebrew_pkgs
  setup_ssh
  clone_repos
  install_rust
  install_nvm_nodejs
  install_uv
  run_other_setups
}

# Run the main function
main
