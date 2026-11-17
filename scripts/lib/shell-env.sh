#!/usr/bin/env bash
# Shared helpers for registering environment setup in fish, zsh and bash.
#
# Single source of truth per shell:
#   fish  -> ~/.config/fish/conf.d/*.fish   (stowed from dotfiles/fish)
#   zsh   -> ~/.zshrc                       (stowed from dotfiles/zsh)
#   bash  -> ~/.bashrc                      (no XDG config; managed via blocks)
#
# Scripts source this file and use install_bash_env() for anything bash needs.
# fish and zsh are covered by the dotfiles themselves, so scripts only need to
# keep the *bash* side in sync (plus install the binaries/plugins).
#
# Sourced, not executed.

# Guard against double-sourcing
if [ -n "${_DOTFILES_SHELL_ENV_LOADED:-}" ]; then
  return 0
fi
_DOTFILES_SHELL_ENV_LOADED=1

# _dotfiles_replace_block <file> <id> <body>
# Replaces (or appends) a marked block in <file>. Follows symlinks so that a
# stowed ~/.zshrc keeps pointing into the dotfiles repo instead of being
# replaced by a regular file.
_dotfiles_replace_block() {
  local file="$1" id="$2" body="$3"
  local begin="# >>> dotfiles:${id} >>>"
  local end="# <<< dotfiles:${id} <<<"
  local target tmp

  target="$(readlink -f "$file" 2>/dev/null || true)"
  [ -n "$target" ] || target="$file"
  mkdir -p "$(dirname "$target")" || return 1
  touch "$target" || return 1

  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-env.XXXXXX")" || return 1
  awk -v b="$begin" -v e="$end" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    skip != 1 { print }
  ' "$target" >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  cat "$tmp" >"$target" || {
    rm -f "$tmp"
    return 1
  }
  rm -f "$tmp"

  {
    printf '%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >>"$target"
}

# install_bash_env <id> <body>
# Idempotently registers a snippet in ~/.bashrc.
install_bash_env() {
  local id="$1" body="$2"
  _dotfiles_replace_block "$HOME/.bashrc" "$id" "$body"
}

# install_fish_conf <name> <body>
# Writes ~/.config/fish/conf.d/<name>.fish (overwrites; follows symlinks).
install_fish_conf() {
  local name="$1" body="$2"
  local file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/${name}.fish"
  local target tmp

  target="$(readlink -f "$file" 2>/dev/null || true)"
  [ -n "$target" ] || target="$file"
  mkdir -p "$(dirname "$target")" || return 1

  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-env.XXXXXX")" || return 1
  printf '%s\n' "$body" >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  cat "$tmp" >"$target" || {
    rm -f "$tmp"
    return 1
  }
  rm -f "$tmp"
}

# path_export_line <dir>
# Prints a POSIX snippet that prepends <dir> to PATH exactly once at runtime.
path_export_line() {
  printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac' "$1" "$1"
}
