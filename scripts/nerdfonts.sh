#!/bin/bash

# 1. Define the fonts you want (Match the names on Nerd Fonts GitHub)
# Common options: JetBrainsMono, FiraCode, Hack, Iosevka, RobotoMono
FONTS=("JetBrainsMono" "FiraCode" "Hack", "MesloLG", "CommitMono")

# 2. Versioning
VERSION="v3.4.0" # Always check for the latest release version
FONT_DIR="$HOME/.local/share/fonts/nerd-fonts"

echo "--- Starting Nerd Font Installation ---"
mkdir -p "$FONT_DIR"

for FONT in "${FONTS[@]}"; do
  if [ -d "$FONT_DIR/$FONT" ]; then
    echo "--> $FONT is already installed. Skipping..."
    continue
  fi

  echo "--> Downloading $FONT..."
  URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT}.tar.xz"

  # Download to a temporary location
  curl -fLo "/tmp/${FONT}.tar.xz" "$URL"

  if [ $? -eq 0 ]; then
    echo "--> Extracting $FONT..."
    mkdir -p "$FONT_DIR/$FONT"
    tar -xvf "/tmp/${FONT}.tar.xz" -C "$FONT_DIR/$FONT"
    rm "/tmp/${FONT}.tar.xz"
  else
    echo "ERROR: Could not download $FONT. Check the name and version."
  fi
done

# 3. Refresh the system font cache
echo "--- Refreshing Font Cache ---"
fc-cache -fv

echo "Done! All fonts are installed in $FONT_DIR"
