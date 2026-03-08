#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for chrome.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

mkdir -p "$HOME/Desktop"
sed -i 's/-stable//g' /usr/share/applications/google-chrome.desktop || true
cp /usr/share/applications/google-chrome.desktop "$HOME/Desktop/"
chown 1000:1000 "$HOME/Desktop/google-chrome.desktop" || true
chmod +x "$HOME/Desktop/google-chrome.desktop"
