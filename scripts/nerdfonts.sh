#!/bin/bash

set -euo pipefail

# 1. Define the fonts you want (Match the names on Nerd Fonts GitHub)
# Common options: JetBrainsMono, FiraCode, Hack, Iosevka, RobotoMono
FONTS=("JetBrainsMono" "FiraCode" "Hack" "CommitMono" "VictorMono" "ZedMono")

# 2. Versioning
VERSION="v3.4.0" # Always check for the latest release version
FONT_DIR="${FONT_DIR:-$HOME/.local/share/fonts}"

# 3. Ensure required tools are available (Arch: fontconfig provides fc-cache)
for tool in curl jq unzip fc-cache; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' is required but not installed."
    echo "Install it with: sudo pacman -S --needed curl jq unzip fontconfig"
    exit 1
  fi
done

# 4. Install the Iosevka family system-wide (/usr/share/fonts/iosevka).
#    Downloads every PkgTTC-Iosevka* asset (base + Slab/Curly/Aile/Etoile/SS01-18)
#    from the latest GitHub release.
IOSEVKA_SYSTEM_DIR="/usr/share/fonts/iosevka"

install_iosevka() {
  echo "--- Installing Iosevka fonts system-wide ---"

  local api="https://api.github.com/repos/be5invis/Iosevka/releases/latest"
  local version
  version="$(curl -fsSL "$api" | jq -r '.tag_name')"

  if [ -f "$IOSEVKA_SYSTEM_DIR/.version" ] &&
    [ "$(cat "$IOSEVKA_SYSTEM_DIR/.version")" = "$version" ]; then
    echo "--> Iosevka $version is already installed in $IOSEVKA_SYSTEM_DIR. Skipping..."
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  echo "--> Downloading Iosevka $version packages (this is a large download)..."
  (
    cd "$tmp" || return 1
    curl -fsSL "$api" |
      jq -r '.assets[] | select(.name | startswith("PkgTTC-Iosevka")) | .browser_download_url' |
      xargs -n 1 curl -fL -O --silent --show-error
  )

  echo "--> Extracting fonts..."
  mkdir -p "$tmp/fonts"
  local zip
  for zip in "$tmp"/*.zip; do
    unzip -qo "$zip" -d "$tmp/fonts"
  done

  echo "--> Copying fonts to $IOSEVKA_SYSTEM_DIR (requires sudo)..."
  sudo rm -rf "$IOSEVKA_SYSTEM_DIR"
  sudo mkdir -p "$IOSEVKA_SYSTEM_DIR"
  sudo find "$tmp/fonts" -type f \
    \( -iname '*.ttc' -o -iname '*.ttf' -o -iname '*.otf' \) \
    -exec cp -f {} "$IOSEVKA_SYSTEM_DIR/" \;
  echo "$version" | sudo tee "$IOSEVKA_SYSTEM_DIR/.version" >/dev/null

  echo "--> Refreshing system font cache..."
  sudo fc-cache -f "$IOSEVKA_SYSTEM_DIR" >/dev/null
  echo "--> Iosevka $version installed system-wide."
}

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

# 5. Install Iosevka system-wide
install_iosevka

# 6. Refresh the user font cache
echo "--- Refreshing Font Cache ---"
fc-cache -fv

echo "Done! All fonts are installed in $FONT_DIR"
echo "Iosevka is installed system-wide in $IOSEVKA_SYSTEM_DIR"
