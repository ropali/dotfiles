#!/bin/bash

# General development tools setup script
# This script installs development tools that are not distro-specific.
# Shell integration: fish + zsh come from the stowed dotfiles, bash is kept in
# sync through scripts/lib/shell-env.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/shell-env.sh
. "$SCRIPT_DIR/lib/shell-env.sh"

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

  if ! command -v stow >/dev/null 2>&1; then
    print_warning "stow not found. Install it with: sudo pacman -S stow"
    return 0
  fi

  local -a packages=(nvim tmux systemd fish starship fastfetch ghostty)

  # zsh is handled by zsh.sh, which backs up a pre-existing ~/.zshrc first.
  if [ -L "$HOME/.zshrc" ]; then
    packages+=(zsh)
  fi

  local pkg
  for pkg in "${packages[@]}"; do
    [ -d "$DOTFILES_DIR/$pkg" ] || continue
    if stow --dir "$DOTFILES_DIR" --target "$HOME" --restow "$pkg"; then
      print_success "Stowed $pkg"
    else
      print_warning "Could not stow $pkg (conflicting files); resolve manually, then re-run"
    fi
  done

  if [ ! -L "$HOME/.zshrc" ]; then
    print_warning "~/.zshrc is not stowed yet; run scripts/zsh.sh to install the zsh config"
  fi

  print_success "Dotfiles stowing complete"
}

###############################################################################
# SECTION: Package Managers
###############################################################################

install_arch_extras() {
  print_section "📦 Arch Extra Packages"
  print_item "Installing lazygit and lazydocker..."
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm lazygit lazydocker
    print_success "lazygit and lazydocker installed"
  else
    print_warning "pacman not found. Skipping Arch extra packages."
  fi
}

install_uv() {
  print_section "🐍 Python Tools (uv)"

  if command -v uv >/dev/null 2>&1; then
    print_warning "uv is already installed."
  else
    print_item "Installing uv package manager..."
    # UV_NO_MODIFY_PATH keeps the installer from editing shell rc files; the
    # dotfiles (fish/zsh) and install_bash_env() below handle integration.
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    print_success "uv installed"
  fi

  # Make it available in the current shell
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

  install_bash_env uv "$(cat <<'EOF'
# uv
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
EOF
)"

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

  print_item "Cloning wallpapers..."
  mkdir -p ~/Pictures
  cd ~/Pictures
  if [ -d ~/Pictures/wallpapers ]; then
    print_warning "Wallpapers directory already exists. Skipping clone."
  else
    git clone https://github.com/FrenzyExists/wallpapers.git
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

  if [ -x "$HOME/.cargo/bin/rustc" ] || command -v rustc >/dev/null 2>&1; then
    print_warning "Rust is already installed. Skipping."
  else
    print_item "Installing Rust..."
    # --no-modify-path: the dotfiles and install_bash_env() own shell setup.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    print_success "Rust installed"
  fi

  export PATH="$HOME/.cargo/bin:$PATH"
  install_bash_env rust "$(cat <<'EOF'
# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) export PATH="$HOME/.cargo/bin:$PATH" ;; esac
EOF
)"
  print_success "Rust wired for bash (fish/zsh come from the dotfiles)"
}

install_nvm_posix() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    print_item "Installing nvm for bash/zsh into $NVM_DIR..."
    # PROFILE=/dev/null stops the installer from editing rc files; the marked
    # block below is the only thing that touches ~/.bashrc.
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
  else
    print_warning "nvm for bash/zsh already present in $NVM_DIR. Reusing."
  fi

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    print_error "nvm (bash/zsh) installation failed"
    return 1
  fi

  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  print_item "Installing Node.js v24 (bash/zsh)..."
  if ! nvm install 24 || ! nvm alias default 24 >/dev/null; then
    print_error "Node.js installation failed (bash/zsh)"
    return 1
  fi
  print_success "Node.js $(node -v) installed for bash/zsh"

  install_bash_env nvm "$(cat <<EOF
# Node.js via nvm
export NVM_DIR="\${NVM_DIR:-$NVM_DIR}"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"
EOF
)"
}

install_nvm_fish() {
  if ! command -v fish >/dev/null 2>&1; then
    print_warning "fish is not installed; skipping fish nvm setup."
    return 0
  fi

  local fish_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
  local base="https://raw.githubusercontent.com/jorgebucaran/nvm.fish/main"
  local f

  print_item "Installing nvm.fish (fish-native NVM)..."
  mkdir -p "$fish_dir/functions" "$fish_dir/conf.d" "$fish_dir/completions"
  for f in \
    functions/nvm.fish \
    functions/_nvm_index_update.fish \
    functions/_nvm_list.fish \
    functions/_nvm_version_activate.fish \
    functions/_nvm_version_deactivate.fish \
    conf.d/nvm.fish \
    completions/nvm.fish; do
    curl -fsSL "$base/$f" -o "$fish_dir/$f" || {
      print_error "Failed to download $f"
      return 1
    }
  done

  touch "$fish_dir/fish_plugins"
  grep -Fxq 'jorgebucaran/nvm.fish' "$fish_dir/fish_plugins" ||
    printf 'jorgebucaran/nvm.fish\n' >>"$fish_dir/fish_plugins"

  print_item "Installing Node.js v24 (fish)..."
  if fish -c 'nvm install 24; and set -U nvm_default_version $nvm_current_version'; then
    print_success "Node.js $(fish -lic 'node -v' 2>/dev/null) installed for fish"
  else
    print_error "fish nvm setup failed"
    return 1
  fi
}

install_nvm_nodejs() {
  print_section "⬢ Node.js (via NVM)"
  install_nvm_posix
  install_nvm_fish

  print_item "Verifying installations..."
  bash -c ". \"$NVM_DIR/nvm.sh\" && node -v && npm -v" 2>/dev/null ||
    print_warning "bash: node/npm verification failed"
  fish -lic 'node -v; npm -v' 2>/dev/null ||
    print_warning "fish: restart the shell (or run 'exec fish') to pick up node"
  print_success "Node.js and npm verified"
}

install_flatpaks() {
  print_section "Flatpak Softwares"

  if ! command -v flatpak >/dev/null 2>&1; then
    print_item "Installing flatpak..."
    sudo pacman -S --needed --noconfirm flatpak
  fi

  print_item "Ensuring the Flathub remote exists..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  print_item "Installing flatpak applications..."
  flatpak install -y flathub com.google.Chrome app.zen_browser.zen com.vivaldi.Vivaldi
  print_success "Flatpak applications installed"
}

###############################################################################
# SECTION: Additional Setup Scripts
###############################################################################

run_other_setups() {
  print_section "🔧 Additional Setup Scripts"

  local script_dir="$SCRIPT_DIR"

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
# ARGUMENT PARSING
###############################################################################

print_usage() {
  cat <<'EOF'
Usage: dev-tools.sh [--only <list>] [--exclude <list>]

Options:
  --only <list>     Comma-separated list of components to install (default: all)
  --exclude <list>  Comma-separated list of components to skip
  -h, --help        Show this help and exit

Components:
  stow, extras, flatpaks, uv, ssh, clone, rust, nvm, other_setups
EOF
}

parse_csv_list() {
  local input="$1"
  local -a items=()
  local old_ifs="$IFS"
  IFS=',' read -r -a items <<<"$input"
  IFS="$old_ifs"
  echo "${items[@]}"
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
  print_header "🛠️  DEVELOPMENT TOOLS INSTALLATION"

  # Map component names to functions
  declare -A STEPS=(
    [stow]=stow_config
    [extras]=install_arch_extras
    [flatpaks]=install_flatpaks
    [uv]=install_uv
    [ssh]=setup_ssh
    [clone]=clone_repos
    [rust]=install_rust
    [nvm]=install_nvm_nodejs
    [other_setups]=run_other_setups
  )

  local -a only_list=()
  local -a exclude_list=()

  while [ $# -gt 0 ]; do
    case "$1" in
    --only)
      shift
      [ -z "$1" ] && {
        print_error "--only requires a value"
        print_usage
        exit 1
      }
      read -r -a only_list <<<"$(parse_csv_list "$1")"
      ;;
    --exclude)
      shift
      [ -z "$1" ] && {
        print_error "--exclude requires a value"
        print_usage
        exit 1
      }
      read -r -a exclude_list <<<"$(parse_csv_list "$1")"
      ;;
    -h | --help)
      print_usage
      exit 0
      ;;
    *)
      print_error "Unknown argument: $1"
      print_usage
      exit 1
      ;;
    esac
    shift
  done

  # Build initial execution list
  local -a exec_list=()
  if [ ${#only_list[@]} -gt 0 ]; then
    exec_list=("${only_list[@]}")
  else
    exec_list=("${!STEPS[@]}")
  fi

  # Validate requested components
  for item in "${exec_list[@]}"; do
    if [ -z "${STEPS[$item]}" ]; then
      print_error "Unknown component: $item"
      print_usage
      exit 1
    fi
  done
  for item in "${exclude_list[@]}"; do
    if [ -z "${STEPS[$item]}" ]; then
      print_error "Unknown component in exclude list: $item"
      print_usage
      exit 1
    fi
  done

  # Build exclude lookup
  declare -A EXCLUDE=()
  for item in "${exclude_list[@]}"; do
    EXCLUDE["$item"]=1
  done

  # Run selected steps in a stable order
  local -a ordered_steps=(
    stow
    extras
    flatpaks
    uv
    ssh
    clone
    rust
    nvm
    other_setups
  )

  local step
  for step in "${ordered_steps[@]}"; do
    # Skip if not in exec_list
    if [ ${#only_list[@]} -gt 0 ]; then
      local found=0
      local item
      for item in "${exec_list[@]}"; do
        if [ "$item" = "$step" ]; then
          found=1
          break
        fi
      done
      [ $found -eq 0 ] && continue
    fi

    # Skip excluded
    if [ -n "${EXCLUDE[$step]}" ]; then
      print_warning "Skipping $step (excluded)"
      continue
    fi

    "${STEPS[$step]}"
    print_divider
  done

  print_header "✅ DEVELOPMENT TOOLS INSTALLED SUCCESSFULLY"
}

# Run the main function
main "$@"
