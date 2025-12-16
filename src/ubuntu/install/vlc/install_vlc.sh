#!/usr/bin/env bash
# This script install vlc. It is meant to be called from inside a Dockerfile.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing VLC ======="

echo "Step 1: Install VLC package..."
apt_update_if_needed
apt_install vlc

echo "Step 2: Desktop shortcut..."
mkdir -p "$HOME/Desktop"

# VLC desktop file name is consistent across Debian-family distros
DESKTOP_FILE="/usr/share/applications/vlc.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  cp "$DESKTOP_FILE" "$HOME/Desktop/vlc.desktop"
  chmod +x "$HOME/Desktop/vlc.desktop"
  chown 1000:1000 "$HOME/Desktop/vlc.desktop" 2>/dev/null || true
fi

echo "VLC installed!"