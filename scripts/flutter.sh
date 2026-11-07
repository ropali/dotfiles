#!/bin/bash
set -euo pipefail

# Flutter SDK setup for Arch-based systems (CachyOS).
# Installs the official stable SDK into ~/flutter (always the latest release),
# rather than pinning a version whose download URL eventually goes stale.

FLUTTER_DIR="$HOME/flutter"
RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

# 1. Build/runtime dependencies required by Flutter on Linux
echo "Installing required packages for Flutter development..."
sudo pacman -S --needed --noconfirm \
  clang cmake ninja pkgconf gtk3 xz mesa git curl jq

FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [ -d "$FLUTTER_DIR" ] && [ -x "$FLUTTER_BIN" ]; then
  echo "Flutter is already installed at $FLUTTER_DIR."
else
  # 2. Resolve the latest stable release from the official manifest
  echo "Resolving latest Flutter stable release..."
  RELEASES_JSON="$(curl -fsSL "$RELEASES_URL")"
  STABLE_HASH="$(jq -r '.current_release.stable' <<<"$RELEASES_JSON")"
  STABLE_VERSION="$(jq -r --arg h "$STABLE_HASH" \
    '.releases[] | select(.hash == $h) | .version' <<<"$RELEASES_JSON")"
  STABLE_ARCHIVE="$(jq -r --arg h "$STABLE_HASH" \
    '.releases[] | select(.hash == $h) | .archive' <<<"$RELEASES_JSON")"

  if [ -z "$STABLE_VERSION" ] || [ -z "$STABLE_ARCHIVE" ] || [ "$STABLE_VERSION" = "null" ]; then
    echo "ERROR: Could not determine the latest Flutter stable release."
    exit 1
  fi

  DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/$STABLE_ARCHIVE"
  echo "Latest stable: $STABLE_VERSION"

  # 3. Download and extract into a temporary directory (not the CWD/Downloads)
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/flutter.XXXXXX")"
  trap 'rm -rf "$TMP_DIR"' EXIT

  echo "Downloading $DOWNLOAD_URL ..."
  curl -fL --progress-bar "$DOWNLOAD_URL" -o "$TMP_DIR/flutter.tar.xz"

  echo "Extracting Flutter SDK..."
  tar -xf "$TMP_DIR/flutter.tar.xz" -C "$TMP_DIR"

  # 4. Move into place, backing up a broken/partial install if present
  if [ -e "$FLUTTER_DIR" ]; then
    BACKUP="${FLUTTER_DIR}.bak-$(date +%Y%m%d%H%M%S)"
    echo "Existing $FLUTTER_DIR is not a valid SDK; moving it to $BACKUP"
    mv "$FLUTTER_DIR" "$BACKUP"
  fi
  mv "$TMP_DIR/flutter" "$FLUTTER_DIR"
fi

# 5. Ensure Flutter is on PATH for zsh. The dotfiles repo already ships this
# line, so only add it when missing (avoids the duplicates older runs created).
ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/flutter/bin:$PATH"'
if [ -f "$ZSHRC" ] && ! grep -Fxq "$PATH_LINE" "$ZSHRC"; then
  echo "Adding Flutter to PATH in $ZSHRC..."
  printf '\n# Flutter\n%s\n' "$PATH_LINE" >>"$ZSHRC"
fi

# Make it available for the verification below too (no sourcing of zsh config).
export PATH="$FLUTTER_DIR/bin:$PATH"

# 6. Verify
echo "Verifying Flutter installation..."
flutter --version

echo ""
echo "Flutter setup complete."
echo "Run 'flutter doctor' to check for additional dependencies."
echo "Android toolchain setup is handled by scripts/setup_android.sh."
