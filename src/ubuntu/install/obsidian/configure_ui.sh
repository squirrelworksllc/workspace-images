#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for obsidian.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

  echo "ERROR: obsidian.desktop not found after extraction" >&2
  exit 1
fi

sed -i 's@^Exec=.*@Exec=/opt/Obsidian/squashfs-root/launcher@g' "$DESKTOP_SRC"
sed -i 's@^Icon=.*@Icon=/opt/Obsidian/squashfs-root/obsidian.png@g' "$DESKTOP_SRC"

mkdir -p "$HOME/Desktop"
cp "$DESKTOP_SRC" "$HOME/Desktop/obsidian.desktop"
cp "$DESKTOP_SRC" /usr/share/applications/obsidian.desktop
chmod +x "$HOME/Desktop/obsidian.desktop" /usr/share/applications/obsidian.desktop
chown 1000:1000 "$HOME/Desktop/obsidian.desktop" 2>/dev/null || true
