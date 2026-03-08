#!/usr/bin/env bash
###############################################################################
# install_vlc.sh
#
# Purpose: Installs vlc.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
# This script install vlc. It is meant to be called from inside a Dockerfile.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log "======= Installing VLC ======="

echo "Step 1: Install VLC package..."
apt_update_if_needed
apt_install vlc

bash "${INST_DIR}/ubuntu/install/vlc/configure_ui.sh"

# VLC desktop file name is consistent across Debian-family distros
DESKTOP_FILE="/usr/share/applications/vlc.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  cp "$DESKTOP_FILE" "$HOME/Desktop/vlc.desktop"
  chmod +x "$HOME/Desktop/vlc.desktop"
  chown 1000:1000 "$HOME/Desktop/vlc.desktop" 2>/dev/null || true
fi

log "VLC installed!"
