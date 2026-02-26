#!/bin/bash

# Script to install GNOME themes and icons from local .tar.xz files
# Themes are moved to ~/.themes and icons to ~/.icons
# Usage: ./themes.sh [themes|icons|all]

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directories
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"

# Create target directories if they don't exist
mkdir -p "$THEMES_DIR"
mkdir -p "$ICONS_DIR"

# Function to install from a local .tar.xz file
install_archive() {
    local archive_file=$1
    local target_dir=$2
    local item_name=$(basename "$archive_file" .tar.xz)
    local temp_dir=$(mktemp -d)
    local current_date=$(date +%Y%m%d)

    echo "Installing: $item_name..."

    # Extract the archive to temp directory
    if ! tar -xf "$archive_file" -C "$temp_dir"; then
        echo "Failed to extract $archive_file"
        rm -rf "$temp_dir"
        return 1
    fi

    # Create the final destination directory name
    local dest_name="$item_name"
    local item_dest_dir="$target_dir/$dest_name"

    # Backup existing item if present
    if [ -d "$item_dest_dir" ]; then
        local backup_name="${dest_name}-${current_date}-OLD"
        # Remove old backup if it exists to avoid conflicts
        if [ -d "$target_dir/$backup_name" ]; then
            rm -rf "$target_dir/$backup_name"
        fi
        echo "  Backing up existing: $dest_name -> $backup_name"
        mv "$item_dest_dir" "$target_dir/$backup_name"
    fi

    # Create the destination directory and move all extracted contents into it
    mkdir -p "$item_dest_dir"
    if mv "$temp_dir"/* "$item_dest_dir/"; then
        echo "  Installed: $dest_name"
    else
        echo "  Failed to install: $dest_name"
        rm -rf "$temp_dir" "$item_dest_dir"
        return 1
    fi

    # Clean up temp directory
    rm -rf "$temp_dir"
}

# Function to install themes
install_themes() {
    echo "=== Installing GNOME themes ==="
    echo "Source: $SCRIPT_DIR"
    echo "Target: $THEMES_DIR"
    echo ""

    local theme_count=0
    for theme_file in "$SCRIPT_DIR"/*.tar.xz; do
        if [ -f "$theme_file" ]; then
            install_archive "$theme_file" "$THEMES_DIR"
            ((theme_count++))
            echo ""
        fi
    done

    if [ $theme_count -eq 0 ]; then
        echo "No .tar.xz theme files found in $SCRIPT_DIR"
    else
        echo "=== Theme installation complete ==="
        echo "Installed $theme_count theme(s) to $THEMES_DIR"
        echo ""
        echo "Available themes:"
        ls -1 "$THEMES_DIR"
    fi
}

# Function to install icons
install_icons() {
    local icons_dir="$SCRIPT_DIR/icons"

    echo "=== Installing icons ==="
    echo "Source: $icons_dir"
    echo "Target: $ICONS_DIR"
    echo ""

    # Check if icons directory exists
    if [ ! -d "$icons_dir" ]; then
        echo "Icons directory not found: $icons_dir"
        return 1
    fi

    local icon_count=0
    for icon_file in "$icons_dir"/*.tar.xz; do
        if [ -f "$icon_file" ]; then
            install_archive "$icon_file" "$ICONS_DIR"
            ((icon_count++))
            echo ""
        fi
    done

    if [ $icon_count -eq 0 ]; then
        echo "No .tar.xz icon files found in $icons_dir"
    else
        echo "=== Icon installation complete ==="
        echo "Installed $icon_count icon pack(s) to $ICONS_DIR"
        echo ""
        echo "Available icons:"
        ls -1 "$ICONS_DIR"
    fi
}

# Main function
main() {
    local command="${1:-all}"

    case "$command" in
        themes)
            install_themes
            ;;
        icons)
            install_icons
            ;;
        all)
            install_themes
            echo ""
            install_icons
            ;;
        *)
            echo "Usage: $0 [themes|icons|all]"
            echo ""
            echo "Commands:"
            echo "  themes  - Install only themes"
            echo "  icons   - Install only icons"
            echo "  all     - Install both themes and icons (default)"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
