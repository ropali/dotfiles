#!/bin/bash

# Main setup script for Arch-based development environment (CachyOS)
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

# Run Arch-specific setup
run_arch_setup() {
    print_subheader "Arch System Setup"
    if [ -f /etc/arch-release ]; then
        if [ -f "$SCRIPT_DIR/arch.sh" ]; then
            bash "$SCRIPT_DIR/arch.sh"
            print_success "Arch setup completed"
        else
            print_warning "arch.sh not found. Skipping Arch-specific setup."
        fi
    else
        print_warning "Not an Arch-based system. Skipping Arch-specific setup."
    fi
}

# Run general development tools setup
run_dev_tools_setup() {
    print_subheader "Development Tools Setup"
    if [ -f "$SCRIPT_DIR/dev-tools.sh" ]; then
        bash "$SCRIPT_DIR/dev-tools.sh" "$@"
        print_success "Development tools setup completed"
    else
        print_warning "dev-tools.sh not found. Skipping development tools setup."
    fi
}

# Main function to run all setups
print_usage() {
    cat <<'EOF'
Usage: main-setup.sh [dev-tools options]

Runs the Arch system setup, then forwards any options to dev-tools.sh:
  --only <list>     Comma-separated components (default: all)
  --exclude <list>  Comma-separated components to skip
  -h, --help        Show this help

dev-tools components:
  stow, extras, flatpaks, uv, ssh, clone, rust, nvm, other_setups
EOF
}

main() {
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        print_usage
        exit 0
    fi

    print_header "🚀 DEVELOPMENT ENVIRONMENT SETUP"

    run_arch_setup
    run_dev_tools_setup "$@"

    print_header "✅ SETUP COMPLETE!"
    echo ""
    echo -e "${GREEN}Your development environment has been configured.${NC}"
    echo -e "${GREEN}Shells: fish and zsh read their configs from ~/dotfiles; bash is kept${NC}"
    echo -e "${GREEN}in sync through marked blocks in ~/.bashrc.${NC}"
    echo -e "${GREEN}You may need to restart your terminal or log out/in for all changes to take effect.${NC}"
    echo ""
    echo -e "${CYAN}Tip: forward component selection to dev-tools, e.g.${NC}"
    echo -e "${CYAN}     scripts/main-setup.sh --only stow,nvm${NC}"
    echo ""
}

# Run the main function
main "$@"
