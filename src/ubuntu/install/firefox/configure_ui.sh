#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for firefox.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

# Desktop shortcut (if available)
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/firefox.desktop ]; then
  cp /usr/share/applications/firefox.desktop "$HOME/Desktop/firefox.desktop"
elif [ -f /usr/share/applications/firefox-esr.desktop ]; then
  cp /usr/share/applications/firefox-esr.desktop "$HOME/Desktop/firefox.desktop"
fi
