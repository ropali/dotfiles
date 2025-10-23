# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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


. "$HOME/.local/bin/env"
. "$HOME/.cargo/env"

export PATH=${PATH}:`go env GOPATH`/bin

alias sv="source .venv/bin/activate"
alias sz="source ~/.zshrc"

eval "$(starship init zsh)"



