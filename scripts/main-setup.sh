#!/bin/bash

# Main setup script for Fedora-based development environment
# This script orchestrates the setup by calling distro-specific and general tool setup scripts

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for better visual separation
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print a section header
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}$1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print a subsection header
print_subheader() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Run Fedora-specific setup
run_fedora_setup() {
    print_subheader "Fedora System Setup"
    if [ -f "$SCRIPT_DIR/fedora.sh" ]; then
        bash "$SCRIPT_DIR/fedora.sh"
        print_success "Fedora setup completed"
    else
        print_warning "fedora.sh not found. Skipping Fedora-specific setup."
    fi
}

# Run general development tools setup
run_dev_tools_setup() {
    print_subheader "Development Tools Setup"
    if [ -f "$SCRIPT_DIR/dev-tools.sh" ]; then
        bash "$SCRIPT_DIR/dev-tools.sh"
        print_success "Development tools setup completed"
    else
        print_warning "dev-tools.sh not found. Skipping development tools setup."
    fi
}

# Main function to run all setups
main() {
    print_header "🚀 DEVELOPMENT ENVIRONMENT SETUP"

    run_fedora_setup
    run_dev_tools_setup

    print_header "✅ SETUP COMPLETE!"
    echo ""
    echo -e "${GREEN}Your development environment has been configured.${NC}"
    echo -e "${GREEN}You may need to restart your terminal or log out/in for all changes to take effect.${NC}"
    echo ""
}

# Run the main function
main
