#!/bin/bash
set -euo pipefail

# Docker Setup Script for Arch Linux (CachyOS compatible)
# This script installs Docker, configures it, and adds the current user to the docker group.

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1 && docker --version | grep -q "Docker version"; then
  echo "Docker is already installed."
  exit 0
fi

echo "Installing Docker and plugins from Arch repositories..."
sudo pacman -S --needed --noconfirm docker docker-buildx docker-compose

echo "Enabling and starting Docker service..."
sudo systemctl enable --now docker

echo "Testing Docker installation..."
sudo docker run hello-world
sudo docker rmi hello-world
sudo docker system prune -f

echo "Adding user to docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"

echo "Docker installation complete."
echo "Note: You may need to log out and log back in for the group changes to take effect."
echo "To test without logging out, run: sg docker -c 'docker run hello-world'"
