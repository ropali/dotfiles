#!/usr/bin/zsh

# --- Configuration ---
SDK_DIR="$HOME/Android/Sdk"
STUDIO_PARENT_DIR="$HOME/Apps" # Installing in Home to avoid sudo/permission issues across distros
ZSHRC="$HOME/.zshrc"

echo "🚀 Starting Universal Android SDK Setup..."

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

# 2. Download and Install Android SDK Command Line Tools
echo "🌐 Downloading Android SDK Command Line Tools..."
SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip"
wget -O /tmp/commandlinetools.zip "$SDK_TOOLS_URL"

mkdir -p "$SDK_DIR/cmdline-tools"
unzip /tmp/commandlinetools.zip -d "$SDK_DIR/cmdline-tools"
mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"

# Accept licenses
echo "📜 Accepting Android SDK licenses..."
yes | "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK_DIR" --licenses

# Install essential SDK components
echo "📦 Installing Android SDK components..."
"$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK_DIR" "platform-tools" "build-tools;34.0.0" "platforms;android-34" "emulator"

# 3. Install Gradle
echo "🔧 Installing Gradle..."
GRADLE_VERSION="8.5"
GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip"
wget -O /tmp/gradle.zip "$GRADLE_URL"

sudo mkdir -p /opt/gradle
sudo unzip /tmp/gradle.zip -d /opt/gradle
sudo mv /opt/gradle/gradle-${GRADLE_VERSION} /opt/gradle/latest

# 4. Download and Install Android Studio
STUDIO_PARENT_DIR="$HOME/Apps"
if [ -f ~/Downloads/android-studio-linux.tar.gz ]; then
    echo "Using local Android Studio download..."
    TAR_FILE=~/Downloads/android-studio-linux.tar.gz
else
    echo "🌐 Downloading Android Studio..."
    STUDIO_URL="https://dl.google.com/dl/android/studio/install/2024.2.1.11/android-studio-panda1-patch1-linux.tar.gz"
    mkdir -p "$STUDIO_PARENT_DIR"
    wget -O /tmp/android-studio.tar.gz "$STUDIO_URL"
    TAR_FILE=/tmp/android-studio.tar.gz
fi

echo "🏗️ Extracting Android Studio to $STUDIO_PARENT_DIR..."
tar -xzf "$TAR_FILE" -C "$STUDIO_PARENT_DIR"

echo "📝 Creating desktop entry for Android Studio..."
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/android-studio.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Exec=$STUDIO_PARENT_DIR/android-studio/bin/studio.sh
Icon=$STUDIO_PARENT_DIR/android-studio/bin/studio.png
Terminal=false
StartupWMClass=jetbrains-studio
Categories=Development;IDE;
EOF

# 5. Inject Environment Variables into .zshrc (Checking for duplicates)
echo "📝 Configuring .zshrc..."
if ! grep -q "ANDROID_HOME" "$ZSHRC"; then
  cat <<EOF >>"$ZSHRC"

# --- Android SDK ---
export ANDROID_HOME="$SDK_DIR"
export PATH="\$PATH:\$ANDROID_HOME/platform-tools"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="\$PATH:\$ANDROID_HOME/build-tools/34.0.0"
export PATH="\$PATH:\$ANDROID_HOME/emulator"
export GRADLE_HOME="/opt/gradle/latest"
export PATH="\$PATH:\$GRADLE_HOME/bin"
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
echo "4. Verify SDK: adb devices, gradle -v, sdkmanager --list"
echo "--------------------------------------------------------"
