# ~/.zshrc — managed by the dotfiles repo (stow).
# Tool integration is guarded so the file works on a fresh machine as well.

# CachyOS defaults: completion, aliases, prompt helpers
[[ -r /usr/share/cachyos-zsh-config/cachyos-config.zsh ]] &&
  source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# Keep PATH entries unique and put user-local tools first
typeset -U path PATH

# --- User-local paths -------------------------------------------------------
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)
[[ -d "$HOME/.lmstudio/bin" ]] && path+=("$HOME/.lmstudio/bin")
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)

if (( $+commands[go] )); then
  path+=("$(go env GOPATH)/bin")
fi

# --- Tool environments ------------------------------------------------------
# uv
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Node.js via nvm (installed by scripts/dev-tools.sh)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] || NVM_DIR="$HOME/.config/nvm"   # legacy location
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Android SDK + Flutter (installed by scripts/setup_android.sh / flutter.sh)
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
for _dir in \
  "$ANDROID_HOME/cmdline-tools/latest/bin" \
  "$ANDROID_HOME/emulator" \
  "$ANDROID_HOME/platform-tools" \
  "$HOME/flutter/bin"; do
  [[ -d "$_dir" ]] && path=("$_dir" $path)
done
unset _dir

# zsh-autosuggestions (installed by scripts/zsh.sh)
[[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Starship prompt (installed by scripts/starship.sh)
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Locale (also fixes tmux rendering issues on CachyOS)
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Aliases
alias sz="source ~/.zshrc"
alias sv="source .venv/bin/activate"
alias hc="herdr-compose"

# Fastfetch on interactive shells only
if [[ -o interactive ]] && (( $+commands[fastfetch] )); then
  fastfetch
fi
