#!/usr/bin/env bash
# This script installs LibreOffice. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing LibreOffice ======="

echo "Step 1: Install packages..."
apt_update_if_needed
apt_install libreoffice

echo "Step 2: Desktop shortcut..."
mkdir -p "$HOME/Desktop"

if [ -f /usr/share/applications/libreoffice-startcenter.desktop ]; then
  cp /usr/share/applications/libreoffice-startcenter.desktop "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/libreoffice-startcenter.desktop"
  chown 1000:1000 "$HOME/Desktop/libreoffice-startcenter.desktop" 2>/dev/null || true
fi

echo "LibreOffice installed!"
