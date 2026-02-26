#!/bin/bash

# Main setup script for Fedora-based development environment
# This script orchestrates the setup by calling distro-specific and general tool setup scripts

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run Fedora-specific setup
run_fedora_setup() {
  echo "=== Running Fedora-specific setup ==="
  if [ -f "$SCRIPT_DIR/fedora.sh" ]; then
    bash "$SCRIPT_DIR/fedora.sh"
  else
    echo "fedora.sh not found. Skipping Fedora-specific setup."
  fi
}

# Run general development tools setup
run_dev_tools_setup() {
  echo "=== Running development tools setup ==="
  if [ -f "$SCRIPT_DIR/dev-tools.sh" ]; then
    bash "$SCRIPT_DIR/dev-tools.sh"
  else
    echo "dev-tools.sh not found. Skipping development tools setup."
  fi
}

# Main function to run all setups
main() {
  run_fedora_setup
  run_dev_tools_setup
  echo "=== Setup complete! ==="
}

# Run the main function
main
