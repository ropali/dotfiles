# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


export NVM_DIR="$HOME/.nvm"
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


# Alias
alias sz="source ~/.zshrc"

# Android, Flutter setup
export PATH="/opt/flutter/bin:$PATH"

export PATH="/opt/cmdline-tools/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/ropali/.lmstudio/bin"
# End of LM Studio CLI section

# Cargo (Arch package may not create ~/.cargo/env)
export PATH="$HOME/.cargo/bin:$PATH"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export PATH=${PATH}:`go env GOPATH`/bin

alias sv="source .venv/bin/activate"
alias sz="source ~/.zshrc"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(starship init zsh)"

export PATH="$HOME/flutter/bin:$PATH"

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/build-tools/36.1.0/

export PATH="$HOME/.npm-global/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

source "$HOME/.local/bin/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=~/bin:$PATH

# To fix tmux render issue on cachyos
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8


fastfetch


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# Automatically start or attach to a tmux session named 'main'
if [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
    exec tmux new-session -A -s main
fi
