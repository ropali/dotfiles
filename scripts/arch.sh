#!/bin/bash

# Arch Linux specific system setup script (CachyOS compatible)
# This script handles all pacman/AUR related package installations

# Find an AUR helper if one is available
AUR_HELPER=""
for helper in paru yay; do
  if command -v "$helper" >/dev/null 2>&1; then
    AUR_HELPER="$helper"
    break
  fi
done

# Install packages from the official Arch repositories
install_packages() {
  echo "Installing required packages from Arch repositories..."
  sudo pacman -Syu --needed --noconfirm \
    base-devel git curl wget unzip fontconfig xz \
    tmux neovim zsh gnome-tweaks go gtk3 \
    upx sshpass stow fd vlc ghostty \
    hyprpolkitagent
}

# Enable the Hyprland polkit authentication agent for the current user.
# The package ships a systemd user unit plus a D-Bus activation file.
enable_hyprpolkitagent() {
  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  if ! systemctl --user show-environment >/dev/null 2>&1; then
    echo "WARNING: No user systemd session. After logging in, run:"
    echo "         systemctl --user enable --now hyprpolkitagent.service"
    return 0
  fi

  echo "Enabling Hyprland polkit agent (user service)..."
  systemctl --user enable hyprpolkitagent.service

  # Start it now only if we are inside a graphical (Wayland) session
  if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    systemctl --user start hyprpolkitagent.service || true
  fi
}

# Install AUR packages (requires paru or yay)
install_aur_packages() {
  if [ -z "$AUR_HELPER" ]; then
    echo "WARNING: No AUR helper (paru/yay) found. Skipping AUR packages:"
    echo "         gtk-engine-murrine antigravity"
    echo "         Install one (e.g. sudo pacman -S --needed base-devel && git clone https://aur.archlinux.org/paru.git) and re-run."
    return 0
  fi

  echo "Installing AUR packages with $AUR_HELPER..."
  "$AUR_HELPER" -S --needed --noconfirm gtk-engine-murrine antigravity
}

# Main function to run all Arch-specific setups
main() {
  install_packages
  install_aur_packages
  enable_hyprpolkitagent
}

# Run the main function
main
