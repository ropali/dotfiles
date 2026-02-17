#!/bin/bash
set -euo pipefail

# Docker Setup Script for Fedora
# This script installs Docker CE, configures it, and adds the current user to the docker group.

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1 && docker --version | grep -q "Docker version"; then
  echo "Docker is already installed."
  exit 0
fi

echo "Removing old Docker packages if present..."
sudo dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine 2>/dev/null || true

echo "Adding Docker CE repository..."
sudo curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

echo "Installing Docker CE..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling and starting Docker service..."
sudo systemctl enable --now docker

echo "Testing Docker installation..."
sudo docker run hello-world
sudo docker rmi hello-world
sudo docker system prune -f

echo "Adding user to docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"
newgrp docker

echo "Testing docker without sudo..."
docker run hello-world

echo "Docker installation complete."
echo "Note: You may need to log out and log back in for the group changes to take effect, or run 'newgrp docker' in your current session."
echo "To test without logging out, run: sg docker -c 'docker run hello-world'"

