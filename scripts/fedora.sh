#!/bin/bash

# Fedora-specific system setup script
# This script handles all Fedora/DNF related package installations

# Function to install required packages from Fedora repositories
install_packages() {
  echo "Installing required packages from Fedora repositories..."
  sudo dnf install tmux nvim zsh gnome-tweaks golang gtk-murrine-engine upx sshpass stow -y --skip-unavailable
}

# Function to install Ghostty from COPR
install_ghostty() {
  echo "Installing Ghostty from COPR..."
  sudo dnf copr enable scottames/ghostty -y
  sudo dnf install ghostty -y
}

# Function to install Google Antigravity from custom repository
install_google_antigravity() {
  echo "Installing Google Antigravity..."
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

# Main function to run all Fedora-specific setups
main() {
  install_packages
  install_ghostty
  install_google_antigravity
}

# Run the main function
main
