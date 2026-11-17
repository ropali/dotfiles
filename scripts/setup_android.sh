#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/shell-env.sh
. "$SCRIPT_DIR/lib/shell-env.sh"

# Android Development Setup for Arch-based systems (CachyOS)
# Installs Android Studio, the SDK (cmdline-tools, build-tools, emulator),
# completes the SDK (platform-tools + a platform, licenses), and installs
# Flutter. Packages come from the AUR + official repos instead of fixed-version
# tarballs from Google (those URLs go stale and break).

# Android platform API level installed via sdkmanager (override: API_LEVEL=35 ...)
API_LEVEL="${API_LEVEL:-36}"

if [ ! -f /etc/arch-release ]; then
  echo "This script supports Arch-based systems only (Arch, CachyOS, Manjaro...)."
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as a normal user; it uses sudo where needed."
  exit 1
fi

# --- Detect an AUR helper ---------------------------------------------------
AUR_HELPER=""
for helper in paru yay; do
  if command -v "$helper" >/dev/null 2>&1; then
    AUR_HELPER="$helper"
    break
  fi
done

if [ -z "$AUR_HELPER" ]; then
  echo "ERROR: No AUR helper (paru or yay) found."
  echo "Install one first, e.g.:"
  echo "  sudo pacman -S --needed base-devel git"
  echo "  git clone https://aur.archlinux.org/paru.git /tmp/paru"
  echo "  (cd /tmp/paru && makepkg -si)"
  exit 1
fi

echo "Using AUR helper: $AUR_HELPER"

# --- Package lists ----------------------------------------------------------
# Official repos
REPO_PKGS=(
  jdk17-openjdk
  gradle
  android-tools      # adb, fastboot
  android-udev       # udev rules so adb works without root
  base-devel         # required to build AUR packages
  git
  wget
  tar
  unzip
)

# 32-bit compatibility libraries are only useful if multilib is enabled
if grep -q '^\[multilib\]' /etc/pacman.conf; then
  REPO_PKGS+=(lib32-gcc-libs lib32-ncurses lib32-mesa)
  # CachyOS ships lib32-zlib-ng-compat, which "provides" and "conflicts with"
  # lib32-zlib. Requesting lib32-zlib explicitly makes pacman try to swap in
  # the real package and fail on the conflict, so only ask for it when
  # nothing already provides it.
  if ! pacman -T lib32-zlib >/dev/null 2>&1; then
    REPO_PKGS+=(lib32-zlib)
  fi
else
  echo "WARNING: multilib is not enabled; skipping lib32 packages."
  echo "         Enable it in /etc/pacman.conf if you need 32-bit SDK tools."
fi

# AUR packages. These install into /opt/android-sdk (SDK) and /opt/android-studio.
AUR_PKGS=(
  android-studio
  android-sdk-cmdline-tools-latest
  android-sdk-build-tools
  android-emulator
)

# --- Install ----------------------------------------------------------------
echo "Installing repository packages..."
sudo pacman -Syu --needed --noconfirm "${REPO_PKGS[@]}"

echo "Installing AUR packages with $AUR_HELPER (this can take a while)..."
"$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"

# Make the SDK tools available in this shell (packages ship profile.d files
# that set ANDROID_HOME=/opt/android-sdk and extend PATH for new logins).
for profile in \
  /etc/profile.d/android-sdk-cmdline-tools-latest.sh \
  /etc/profile.d/android-emulator.sh; do
  if [ -r "$profile" ]; then
    # shellcheck source=/dev/null
    . "$profile"
  fi
done

# --- Complete the SDK -------------------------------------------------------
# The packages install cmdline-tools, build-tools and the emulator, but Flutter
# and Studio also need platform-tools and a platform. The SDK is root-owned, so
# these steps go through sudo.
SDKMANAGER="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKMANAGER" ]; then
  echo "Accepting Android SDK licenses..."
  # 'yes' exits with SIGPIPE once sdkmanager stops reading, so disable pipefail
  # here to avoid a false failure.
  set +o pipefail
  if ! yes | sudo env ANDROID_HOME=/opt/android-sdk "$SDKMANAGER" --licenses >/dev/null; then
    echo "WARNING: Could not auto-accept licenses; accept them in Android Studio."
  fi
  set -o pipefail

  echo "Installing platform-tools and platforms;android-${API_LEVEL}..."
  sudo env ANDROID_HOME=/opt/android-sdk "$SDKMANAGER" --install \
    "platform-tools" "platforms;android-${API_LEVEL}" \
    || echo "WARNING: Could not install platform-tools/platform."

  # sdkmanager (running as root) writes some files as 0744, so the invoking
  # user can read but not execute adb/fastboot. Make the SDK readable and keep
  # the executable bit where it already exists for the owner.
  echo "Fixing SDK file permissions..."
  sudo chmod -R a+rX /opt/android-sdk

  # Use the pacman-managed adb/fastboot everywhere so there is a single adb on
  # the system (avoids Flutter's "multiple adb binaries" conflict).
  if [ -x /usr/bin/adb ]; then
    sudo ln -sf /usr/bin/adb      /opt/android-sdk/platform-tools/adb
    sudo ln -sf /usr/bin/fastboot /opt/android-sdk/platform-tools/fastboot
  fi
else
  echo "WARNING: sdkmanager not found at $SDKMANAGER."
fi

# --- Flutter ----------------------------------------------------------------
FLUTTER_DIR="$HOME/flutter"
if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter already installed at $FLUTTER_DIR; skipping clone."
else
  echo "Installing Flutter (stable) to $FLUTTER_DIR (large download)..."
  git clone -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

echo "Initializing Flutter (first run downloads the Dart SDK)..."
"$FLUTTER_DIR/bin/flutter" --version >/dev/null

# Make Flutter available for verification in this shell (the dotfiles' fish/
# zsh configs add ~/flutter/bin to PATH for interactive shells).
export PATH="$FLUTTER_DIR/bin:$PATH"

# --- Device access groups ---------------------------------------------------
echo "Configuring device access groups..."
sudo groupadd -f adbusers 2>/dev/null || true
sudo usermod -aG adbusers "$USER" 2>/dev/null || true

if [ -e /dev/kvm ]; then
  sudo usermod -aG kvm "$USER" 2>/dev/null || true
else
  echo "WARNING: /dev/kvm not found; the emulator needs hardware virtualization"
  echo "         (enable VT-x/AMD-V and the kvm module)."
fi

# --- Stale config from the old script --------------------------------------
if grep -q '^# --- Android SDK ---' "$HOME/.zshrc" 2>/dev/null; then
  echo "WARNING: ~/.zshrc still contains the old Android SDK block pointing at"
  echo "         ~/Android/Sdk. The packages now set ANDROID_HOME=/opt/android-sdk"
  echo "         via /etc/profile.d, so remove that old block to avoid conflicts."
fi

# --- Shell integration ------------------------------------------------------
# fish (conf.d/android.fish) and zsh (~/.zshrc) read the SDK location from the
# stowed dotfiles; keep bash in sync with a marked block.
install_bash_env android "$(cat <<'EOF'
# Android SDK + Flutter
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
for _dir in "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools"; do
  if [ -d "$_dir" ]; then
    case ":$PATH:" in
    *":$_dir:"*) ;;
    *) PATH="$_dir:$PATH" ;;
    esac
  fi
done
unset _dir
export PATH
EOF
)"

if [ -f "$HOME/.config/fish/config.fish" ] &&
  [ ! -e "$HOME/.config/fish/conf.d/android.fish" ]; then
  echo "WARNING: fish config is not stowed; run 'cd ~/dotfiles && stow fish'"
  echo "         so ANDROID_HOME and the SDK tools reach fish."
fi

# --- Verify -----------------------------------------------------------------
echo ""
echo "Verifying installation..."
for bin in adb fastboot gradle java sdkmanager avdmanager emulator android-studio flutter dart; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  ✓ $bin -> $(command -v "$bin")"
  else
    echo "  ✗ $bin not found"
  fi
done

echo ""
echo "--------------------------------------------------------"
echo "🏁 ANDROID + FLUTTER SETUP COMPLETE"
echo "  SDK location : /opt/android-sdk (ANDROID_HOME / ANDROID_SDK_ROOT)"
echo "  Flutter      : $FLUTTER_DIR (add ~/flutter/bin to PATH if missing)"
echo "  Studio       : run 'android-studio' or from the app menu"
echo ""
echo "Log out and back in (or reboot) so the 'adbusers'/'kvm' group changes and"
echo "the /etc/profile.d environment variables take effect."
echo "Then verify with: adb devices, flutter doctor, gradle -v"
echo "--------------------------------------------------------"
