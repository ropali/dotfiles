#!/usr/bin/env bash
# Zsh setup: installs zsh, stows the dotfiles' zsh config and installs
# zsh-autosuggestions.
#
# Making zsh the login shell is opt-in:
#   scripts/zsh.sh --set-default
#   SET_DEFAULT_SHELL=1 scripts/zsh.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SET_DEFAULT=0
for arg in "$@"; do
  case "$arg" in
  --set-default)
    SET_DEFAULT=1
    ;;
  -h | --help)
    echo "Usage: zsh.sh [--set-default]"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg" >&2
    exit 1
    ;;
  esac
done
[ "${SET_DEFAULT_SHELL:-0}" = "1" ] && SET_DEFAULT=1

echo "--- Installing zsh ---"
if ! command -v zsh >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm zsh
else
  echo "--> zsh is already installed."
fi

echo "--- Stowing zsh config ---"
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  BACKUP="$HOME/.zshrc.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
  echo "--> Backing up existing ~/.zshrc to $BACKUP"
  mv "$HOME/.zshrc" "$BACKUP"
fi
(cd "$DOTFILES_DIR" && stow --restow zsh)
echo "--> ~/.zshrc -> $(readlink -f "$HOME/.zshrc")"

echo "--- Installing zsh-autosuggestions ---"
PLUGIN_DIR="$HOME/.zsh"
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  mkdir -p "$PLUGIN_DIR"
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
    "$PLUGIN_DIR/zsh-autosuggestions"
else
  echo "--> zsh-autosuggestions already installed."
fi

if [ "$SET_DEFAULT" -eq 1 ]; then
  ZSH_PATH="$(command -v zsh)"
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    echo "--- Setting zsh as your login shell ---"
    chsh -s "$ZSH_PATH"
  else
    echo "--> zsh is already your login shell."
  fi
else
  echo "--> Leaving your login shell unchanged."
  echo "    To make zsh the default: scripts/zsh.sh --set-default"
fi

echo ""
echo "Zsh setup complete. Start it with: zsh"
echo "Note: the fish and bash environments are configured by their own files;"
echo "      zsh reads everything it needs from ~/.zshrc."
