#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for discord.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 3: Fix Desktop files..."
DESKTOP_FILE="/usr/share/applications/discord.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  sed -i 's@^Exec=/usr/share/discord/Discord@Exec=/usr/share/discord/Discord --no-sandbox@g' "$DESKTOP_FILE"

  mkdir -p "$HOME/Desktop"
  cp "$DESKTOP_FILE" "$HOME/Desktop/discord.desktop"
  chmod +x "$HOME/Desktop/discord.desktop"
  chown 1000:1000 "$HOME/Desktop/discord.desktop" || true
fi
