#!/bin/bash

set -euo pipefail

# 1. Define the fonts you want (Match the names on Nerd Fonts GitHub)
# Common options: JetBrainsMono, FiraCode, Hack, Iosevka, RobotoMono
FONTS=("JetBrainsMono" "FiraCode" "Hack" "CommitMono" "VictorMono" "ZedMono")

# 2. Versioning
VERSION="v3.4.0" # Always check for the latest release version
FONT_DIR="${FONT_DIR:-~/.local/share/fonts}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Re-running with sudo to install fonts system-wide into $FONT_DIR..."
  exec sudo FONT_DIR="$FONT_DIR" bash "$0" "$@"
fi

echo "--- Starting Nerd Font Installation ---"
mkdir -p "$FONT_DIR"

for FONT in "${FONTS[@]}"; do
  if [ -d "$FONT_DIR/$FONT" ]; then
    echo "--> $FONT is already installed. Skipping..."
    continue
  fi

  echo "--> Downloading $FONT..."
  URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT}.zip"
  ZIP_PATH="/tmp/${FONT}.zip"

  # Download to a temporary location
  if curl -fLo "$ZIP_PATH" "$URL"; then
    echo "--> Extracting $FONT..."
    mkdir -p "$FONT_DIR/$FONT"
    unzip -o "$ZIP_PATH" -d "$FONT_DIR/$FONT"
    rm -f "$ZIP_PATH"
  else
    echo "ERROR: Could not download $FONT. Check the name and version."
    exit 1
  fi
done

# 3. Refresh the system font cache
echo "--- Refreshing Font Cache ---"
fc-cache -fv

echo "Done! All fonts are installed in $FONT_DIR"
