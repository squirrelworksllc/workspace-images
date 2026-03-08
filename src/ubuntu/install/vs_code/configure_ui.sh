#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for vs_code.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

log "Step 2: Desktop shortcut..."
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/code.desktop ]; then
  cp /usr/share/applications/code.desktop "$HOME/Desktop/code.desktop"
  chmod +x "$HOME/Desktop/code.desktop"
  chown 1000:1000 "$HOME/Desktop/code.desktop" 2>/dev/null || true
fi
