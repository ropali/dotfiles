#!/usr/bin/env bash
# Starship prompt setup for zsh, bash and (optionally) fish.
#
#   scripts/starship.sh           # zsh + bash
#   scripts/starship.sh --fish    # also enable it in fish
#   scripts/starship.sh --set-default  # also make zsh the login shell

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/shell-env.sh
. "$SCRIPT_DIR/lib/shell-env.sh"

INSTALL_FISH=0
SET_DEFAULT=0
for arg in "$@"; do
  case "$arg" in
  --fish)
    INSTALL_FISH=1
    ;;
  --set-default)
    SET_DEFAULT=1
    ;;
  -h | --help)
    echo "Usage: starship.sh [--fish] [--set-default]"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg" >&2
    exit 1
    ;;
  esac
done
[ "${INSTALL_STARSHIP_FISH:-0}" = "1" ] && INSTALL_FISH=1
[ "${SET_DEFAULT_SHELL:-0}" = "1" ] && SET_DEFAULT=1

echo "--- Stowing starship config ---"
(cd "$DOTFILES_DIR" && stow --restow starship)
echo "--> ~/.config/starship.toml -> $(readlink -f "$HOME/.config/starship.toml")"

echo "--- Installing starship ---"
if command -v starship >/dev/null 2>&1; then
  echo "--> starship is already installed: $(starship --version | head -n1)"
else
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "--- Registering starship in bash ---"
install_bash_env starship "$(cat <<'EOF'
# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
EOF
)"

echo "--- Registering starship in zsh ---"
# zsh uses the stowed ~/.zshrc, which already contains the guarded init line.

if [ "$INSTALL_FISH" -eq 1 ]; then
  echo "--- Registering starship in fish ---"
  install_fish_conf starship "$(cat <<'EOF'
if type -q starship
    starship init fish | source
end
EOF
)"
else
  echo "--> fish keeps its current prompt (CachyOS Pure)."
  echo "    Enable Starship in fish with: scripts/starship.sh --fish"
fi

if [ "$SET_DEFAULT" -eq 1 ]; then
  if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
      echo "--- Setting zsh as your login shell ---"
      chsh -s "$ZSH_PATH"
    fi
  else
    echo "WARNING: zsh not installed; run scripts/zsh.sh first."
  fi
fi

echo ""
echo "Starship setup complete."
echo "  zsh : configured via ~/.zshrc"
echo "  bash: configured via ~/.bashrc"
if [ "$INSTALL_FISH" -eq 1 ]; then
  echo "  fish: configured via ~/.config/fish/conf.d/starship.fish"
else
  echo "  fish: untouched (use --fish to enable)"
fi
echo "Open a new shell to see the prompt."
