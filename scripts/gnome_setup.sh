# Install required packages
sudo dnf install tmux nvim zsh gnome-tweaks golang -y --skip-unavailable

# Install Ghostty
dnf copr enable scottames/ghostty
dnf install ghostty -y


# Setup Github SSH key
ssh-keygen -t ed25519 -C "ropali68@gmail.com"

eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519

cat ~/.ssh/id_ed25519

# Clone dotfiles
cd ~
git clone git@github.com:ropali/dotfiles.git

# Clone wallpapers
cd ~/Pictures
git clone git@github.com:FrenzyExists/wallpapers.git


# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
