#!/bin/bash

FLUTTER_DIR="$HOME/flutter"

if [ -d "$FLUTTER_DIR" ] && [ -x "$FLUTTER_DIR/bin/flutter" ]; then
    echo "Flutter is already installed."
else
    # Download Flutter SDK
    echo "Downloading Flutter SDK..."
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.41.1-stable.tar.xz -O ~/Downloads/flutter.tar.xz

    # Extract the archive
    echo "Extracting Flutter SDK..."
    tar -xf ~/Downloads/flutter.tar.xz

    # Move to home directory
    echo "Moving Flutter to $FLUTTER_DIR..."
    mv flutter "$FLUTTER_DIR"

    # Clean up
    rm ~/Downloads/flutter.tar.xz
fi


echo "Installing required packages for Flutter development..."
sudo dnf install -y clang cmake ninja-build gtk3-devel mesa-demos

# Add Flutter to PATH in .zshrc if not already present
if ! grep -q 'export PATH="$PATH:$HOME/flutter/bin"' ~/.zshrc; then
    echo "Adding Flutter to PATH in .zshrc..."
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
    source ~/.zshrc
fi

# Verify installation
echo "Verifying Flutter installation..."
flutter --version

echo "Flutter setup complete. You may need to run 'flutter doctor' to check for additional dependencies."