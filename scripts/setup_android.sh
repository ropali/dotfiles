#!/bin/bash
set -euo pipefail

# Android Development Setup for Arch-based systems (CachyOS)
# Android Studio, the SDK command-line tools, build-tools and the emulator are
# installed as proper packages (AUR + official repos) instead of downloading
# fixed-version tarballs from Google (those URLs go stale and break).

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
  REPO_PKGS+=(lib32-gcc-libs lib32-zlib lib32-ncurses lib32-mesa)
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

# --- Accept SDK licenses ----------------------------------------------------
# The AUR SDK lives in /opt/android-sdk and is root-owned, so licenses must be
# accepted with sudo. Studio and Gradle builds need these accepted.
SDKMANAGER="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKMANAGER" ]; then
  echo "Accepting Android SDK licenses..."
  # 'yes' exits with SIGPIPE once sdkmanager stops reading, so disable pipefail
  # here to avoid a false failure.
  set +o pipefail
  if ! yes | sudo "$SDKMANAGER" --licenses >/dev/null; then
    echo "WARNING: Could not auto-accept licenses; accept them in Android Studio."
  fi
  set -o pipefail
else
  echo "WARNING: sdkmanager not found at $SDKMANAGER."
fi

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

# --- Verify -----------------------------------------------------------------
echo ""
echo "Verifying installation..."
for bin in adb gradle java sdkmanager emulator android-studio; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  ✓ $bin -> $(command -v "$bin")"
  else
    echo "  ✗ $bin not found"
  fi
done

echo ""
echo "--------------------------------------------------------"
echo "🏁 ANDROID SETUP COMPLETE"
echo "  SDK location : /opt/android-sdk (ANDROID_HOME / ANDROID_SDK_ROOT)"
echo "  Studio       : run 'android-studio' or from the app menu"
echo ""
echo "Log out and back in (or reboot) so the 'adbusers'/'kvm' group changes and"
echo "the /etc/profile.d environment variables take effect."
echo "Then verify with: adb devices, sdkmanager --list, gradle -v"
echo "--------------------------------------------------------"
