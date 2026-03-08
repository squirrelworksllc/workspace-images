#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for edge.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

# Desktop shortcut
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/microsoft-edge.desktop ]; then
  cp /usr/share/applications/microsoft-edge.desktop "$HOME/Desktop/microsoft-edge.desktop"
  chmod +x "$HOME/Desktop/microsoft-edge.desktop"
  chown 1000:1000 "$HOME/Desktop/microsoft-edge.desktop" || true
fi
