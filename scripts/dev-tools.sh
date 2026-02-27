#!/bin/bash

# General development tools setup script
# This script installs development tools that are not distro-specific

# Colors for better visual separation
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print a section header
print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${BOLD}$1${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print a subsection header
print_section() {
    echo ""
    echo -e "${CYAN}┌────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} $1"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────────┘${NC}"
}

# Print an item being processed
print_item() {
    echo -e "${BLUE}  →${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}    ✓ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}    ⚠ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}    ✗ $1${NC}"
}

# Print a divider
print_divider() {
    echo ""
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

###############################################################################
# SECTION: Dotfiles Configuration
###############################################################################

stow_config() {
    print_section "📁 Dotfiles Configuration"
    print_item "Stowing dotfiles config..."
    cd ~/dotfiles
    stow nvim tmux
    print_success "Dotfiles stowed successfully"
}

###############################################################################
# SECTION: Package Managers
###############################################################################

install_homebrew() {
    print_section "🍺 Homebrew Package Manager"
    print_item "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
}

install_homebrew_pkgs() {
    print_item "Installing Homebrew packages..."
    brew install jesseduffield/lazydocker/lazydocker
    brew install lazygit
    print_success "Homebrew packages installed"
}

install_uv() {
    print_section "🐍 Python Tools (uv)"
    print_item "Installing uv package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    print_success "uv installed"

    print_item "Installing Ruff Python Linter..."
    uv tool install ruff@latest
    print_success "Ruff installed"
}

###############################################################################
# SECTION: Version Control & SSH
###############################################################################

setup_ssh() {
    print_section "🔐 SSH Key Setup"
    print_item "Setting up GitHub SSH key..."
    if [ -f ~/.ssh/id_ed25519 ]; then
        print_warning "SSH key already exists. Skipping generation."
    else
        read -p "    Enter your email for the SSH key: " email
        ssh-keygen -t ed25519 -C "$email"
        print_success "SSH key generated"
    fi
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    print_success "SSH key added to agent"
    echo ""
    echo -e "${CYAN}    SSH public key:${NC}"
    cat ~/.ssh/id_ed25519.pub
}

clone_repos() {
    print_section "📦 Repository Cloning"

    print_item "Cloning dotfiles..."
    cd ~
    if [ -d ~/dotfiles ]; then
        print_warning "Dotfiles directory already exists. Skipping clone."
    else
        git clone git@github.com:ropali/dotfiles.git
        print_success "Dotfiles cloned"
    fi

    print_item "Cloning wallpapers..."
    mkdir -p ~/Pictures
    cd ~/Pictures
    if [ -d ~/Pictures/wallpapers ]; then
        print_warning "Wallpapers directory already exists. Skipping clone."
    else
        git clone git@github.com:FrenzyExists/wallpapers.git
        print_success "Wallpapers cloned"
    fi

    print_item "Installing TPM (Tmux Plugin Manager)..."
    if [ -d ~/.tmux/plugins/tpm ]; then
        print_warning "TPM already installed. Skipping."
    else
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        print_success "TPM installed"
    fi
}

###############################################################################
# SECTION: Programming Languages
###############################################################################

install_rust() {
    print_section "🦀 Rust Programming Language"
    print_item "Installing Rust..."
    if command -v rustc >/dev/null 2>&1; then
        print_warning "Rust is already installed. Skipping."
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        print_success "Rust installed"
    fi
}

install_nvm_nodejs() {
    print_section "⬢ Node.js (via NVM)"

    print_item "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    print_success "NVM installed"

    # in lieu of restarting the shell
    \. "$HOME/.nvm/nvm.sh"

    print_item "Installing Node.js v24..."
    nvm install 24
    print_success "Node.js installed"

    print_item "Verifying installations..."
    node -v
    npm -v
    print_success "Node.js and npm verified"
}

###############################################################################
# SECTION: Additional Setup Scripts
###############################################################################

run_other_setups() {
    print_section "🔧 Additional Setup Scripts"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    print_item "Running nerdfonts setup..."
    if [ -f "$script_dir/nerdfonts.sh" ]; then
        bash "$script_dir/nerdfonts.sh"
        print_success "Nerdfonts setup completed"
    else
        print_warning "nerdfonts.sh not found, skipping."
    fi

    print_item "Running zsh setup..."
    if [ -f "$script_dir/zsh.sh" ]; then
        bash "$script_dir/zsh.sh"
        print_success "Zsh setup completed"
    else
        print_warning "zsh.sh not found, skipping."
    fi

    print_item "Running starship setup..."
    if [ -f "$script_dir/starship.sh" ]; then
        bash "$script_dir/starship.sh"
        print_success "Starship setup completed"
    else
        print_warning "starship.sh not found, skipping."
    fi

    print_item "Running docker setup..."
    if [ -f "$script_dir/docker.sh" ]; then
        bash "$script_dir/docker.sh"
        print_success "Docker setup completed"
    else
        print_warning "docker.sh not found, skipping."
    fi

    print_item "Running Android setup..."
    if [ -f "$script_dir/setup_android.sh" ]; then
        bash "$script_dir/setup_android.sh"
        print_success "Android setup completed"
    else
        print_warning "setup_android.sh not found, skipping."
    fi

    print_item "Running Flutter setup..."
    if [ -f "$script_dir/flutter.sh" ]; then
        bash "$script_dir/flutter.sh"
        print_success "Flutter setup completed"
    else
        print_warning "flutter.sh not found, skipping."
    fi
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    print_header "🛠️  DEVELOPMENT TOOLS INSTALLATION"

    # Configuration
    stow_config
    print_divider

    # Package Managers
    install_homebrew
    install_homebrew_pkgs
    install_uv
    print_divider

    # Version Control
    setup_ssh
    clone_repos
    print_divider

    # Programming Languages
    install_rust
    install_nvm_nodejs
    print_divider

    # Additional setups
    run_other_setups

    print_header "✅ DEVELOPMENT TOOLS INSTALLED SUCCESSFULLY"
}

# Run the main function
main
