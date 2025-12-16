#!/usr/bin/env bash
# This script installs Filezilla. It is meant to be called from a Dockerfile.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing FileZilla ======="

apt_update_if_needed
apt_install filezilla

# Default settings and desktop icon
mkdir -p "$HOME/.config/filezilla" "$HOME/Desktop"

# Copy default config if it exists in the image
if [ -f ${INST_DIR}/filezilla/filezilla.xml ]; then
  cp ${INST_DIR}/filezilla/filezilla.xml "$HOME/.config/filezilla/filezilla.xml"
  chown 1000:1000 "$HOME/.config/filezilla/filezilla.xml" 2>/dev/null || true
fi

if [ -f /usr/share/applications/filezilla.desktop ]; then
  cp /usr/share/applications/filezilla.desktop "$HOME/Desktop/filezilla.desktop"
  chmod +x "$HOME/Desktop/filezilla.desktop"
  chown 1000:1000 "$HOME/Desktop/filezilla.desktop" 2>/dev/null || true
fi

echo "FileZilla installed!"
