#!/usr/bin/zsh

# --- Configuration ---
SDK_DIR="$HOME/Android/Sdk"
STUDIO_PARENT_DIR="$HOME/Apps" # Installing in Home to avoid sudo/permission issues across distros
ZSHRC="$HOME/.zshrc"

echo "🚀 Starting Universal Android Setup..."

# 1. Distro-Specific Dependency Detection
if [ -f /etc/fedora-release ] || [ -f /etc/nobara-release ]; then
  echo "📦 Detected Fedora/Nobara. Using DNF..."
  sudo dnf install -y java-17-openjdk-devel zlib.i686 ncurses-libs.i686 libstdc++.i686 mesa-libGL.i686 wget tar unzip
elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
  echo "📦 Detected Ubuntu/Debian. Using APT..."
  sudo apt update
  sudo apt install -y openjdk-17-jdk libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 wget tar unzip
elif [ -f /etc/arch-release ]; then
  echo "📦 Detected Arch Linux. Using Pacman..."
  sudo pacman -S --needed jdk17-openjdk lib32-zlib lib32-gcc-libs wget tar unzip
fi

# 2. Download Latest Android Studio
# We fetch the download page and scrape the latest Linux .tar.gz link
echo "🌐 Fetching latest Android Studio download link..."
STUDIO_URL=$(curl -s https://developer.android.com/studio | grep -oP 'https://redirector.gvt1.com/edgedl/android/studio/ide-zips/[^"]*linux.tar.gz' | head -1)

mkdir -p "$STUDIO_PARENT_DIR"
wget -O /tmp/android-studio.tar.gz "$STUDIO_URL"

echo "🏗️ Extracting Android Studio to $STUDIO_PARENT_DIR..."
tar -xzf /tmp/android-studio.tar.gz -C "$STUDIO_PARENT_DIR"

# 3. Initialize SDK Directory
mkdir -p "$SDK_DIR/cmdline-tools"

# 4. Inject Environment Variables into .zshrc (Checking for duplicates)
echo "📝 Configuring .zshrc..."
if ! grep -q "ANDROID_HOME" "$ZSHRC"; then
  cat <<EOF >>"$ZSHRC"

# --- Android SDK ---
export ANDROID_HOME="$SDK_DIR"
export PATH="\$PATH:\$ANDROID_HOME/emulator"
export PATH="\$PATH:\$ANDROID_HOME/platform-tools"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin"
# Auto-detect latest build-tools version
export PATH="\$PATH:\$(find \$ANDROID_HOME/build-tools -maxdepth 1 -not -path \$ANDROID_HOME/build-tools -type d 2>/dev/null | sort -V | tail -n 1)"
EOF
  echo "✅ Added paths to $ZSHRC"
else
  echo "ℹ️ Android paths already exist in $ZSHRC, skipping..."
fi

# 5. Handle KVM Permissions (For Emulator)
sudo usermod -aG kvm $USER 2>/dev/null || echo "⚠️ Could not add to KVM group (ignore if on Mac/WSL)"

echo "--------------------------------------------------------"
echo "🏁 SETUP FINISHED!"
echo "1. Run: source ~/.zshrc"
echo "2. Start Studio: $STUDIO_PARENT_DIR/android-studio/bin/studio.sh"
echo "3. In the Setup Wizard, use '$SDK_DIR' as your SDK path."
echo "--------------------------------------------------------"
