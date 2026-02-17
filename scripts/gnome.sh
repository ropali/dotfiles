#!/bin/bash

# Function to install required packages
install_packages() {
  echo "Installing required packages..."
  sudo dnf install tmux nvim zsh gnome-tweaks golang gtk-murrine-engine -y --skip-unavailable
}

stow_config() {
  echo "Stowing dotfiles config..."
  cd ~/dotfiles
  stow nvim tmux
}

# Function to install Ghostty
install_ghostty() {
  echo "Installing Ghostty..."
  dnf copr enable scottames/ghostty
  dnf install ghostty -y
}

install_homebrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

}

install_homebrew_pkgs() {
  brew install jesseduffield/lazydocker/lazydocker
  brew install lazygit
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
  cd ~/Pictures
  if [ -d ~/Pictures/wallpapers ]; then
    echo "Wallpapers directory already exists. Skipping clone."
  else
    git clone git@github.com:FrenzyExists/wallpapers.git
  fi

  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
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

install_app_launcher() {
  echo "Installing App Launcher..."
  curl -fsSL https://vicinae.com/install.sh | bash

  # stow the config for the app launcher
  cd ~/dotfiles
  stow systemd

  # Enable the service (starts at login)
  systemctl --user enable vicinae.service

  # Start the service now
  systemctl --user start vicinae.service

  # Check status
  systemctl --user --no-pager status vicinae.service

}

install_google_antigavity() {
  echo "Installing Google Antigavity..."
  sudo tee /etc/yum.repos.d/antigravity.repo <<EOL
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL

  sudo dnf makecache

  sudo dnf install antigravity -y

  echo "Google Antigravity installed successfully!"
}

# Function to run other setup scripts in the same folder
run_other_setups() {
  echo "Running other setup scripts..."
  local script_dir="$(pwd)"
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

# Main function to run all setups
main() {
  # install the stow package first to ensure we can stow the configs
  sudo dnf install stow -y
  stow_config
  install_packages
  install_homebrew
  install_homebrew_pkgs
  setup_ssh
  install_ghostty
  clone_repos
  install_rust
  install_app_launcher
  run_other_setups
  install_google_antigavity
}

# Run the main function
main

