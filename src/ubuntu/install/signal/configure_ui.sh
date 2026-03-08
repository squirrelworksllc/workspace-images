#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for signal.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 6: Fixing the desktop icon (best effort)..."
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/signal-desktop.desktop ]; then
  cp /usr/share/applications/signal-desktop.desktop "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/signal-desktop.desktop"
  chown 1000:1000 "$HOME/Desktop/signal-desktop.desktop" 2>/dev/null || true
fi
