#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures the ZBar groups, UI elements, and Start Menu.
###############################################################################
set -euo pipefail

log() { echo "[zbar-ui] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Configuring ZBar UI elements for Kasm workspace..."

# System-wide menu entry
cat > /usr/share/applications/zbarcam.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ZBar Barcode Scanner
Comment=Scan barcodes via webcam
Exec=zbarcam
Icon=scanner
Terminal=false
Categories=Utility;
EOF
chmod 644 /usr/share/applications/zbarcam.desktop

# Desktop shortcut
mkdir -p "${KASM_HOME}/Desktop"
cp /usr/share/applications/zbarcam.desktop "${KASM_HOME}/Desktop/zbarcam.desktop"
chmod +x "${KASM_HOME}/Desktop/zbarcam.desktop"
chown -R 1000:0 "${KASM_HOME}/Desktop" 2>/dev/null || true

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

log "ZBar UI configuration complete."
