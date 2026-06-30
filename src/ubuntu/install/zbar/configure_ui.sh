#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures the ZBar groups, UI elements, and Start Menu.
###############################################################################
set -e

echo "Configuring ZBar UI elements for Kasm workspace..."

DESKTOP_DIR="/home/kasm-default-profile/Desktop"
ZBAR_DESKTOP_FILE="${DESKTOP_DIR}/zbarcam.desktop"

mkdir -p "${DESKTOP_DIR}"

cat > "${ZBAR_DESKTOP_FILE}" << EOF
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

chown -R 1000:1000 /home/kasm-default-profile/Desktop/
chmod +x "${ZBAR_DESKTOP_FILE}"

echo "ZBar UI configuration complete."
