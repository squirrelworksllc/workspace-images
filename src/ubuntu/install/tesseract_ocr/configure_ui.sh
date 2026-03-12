#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements for Tesseract, NormCap, and Documentation.
###############################################################################
set -euo pipefail

log() { echo "[TESSERACT-UI] $*"; }

KASM_HOME="/home/kasm-default-profile"
# Use INST_DIR or fallback to the standard SquirrelWorks path
SOURCE_DIR="${INST_DIR:-/dockerstartup/install}/ubuntu/install/tesseract_ocr"

log "Configuring Tesseract Environment UI..."

# 1. Tesseract CLI Shortcut (The custom .desktop you provided)
if [ -f "${SOURCE_DIR}/tesseract.desktop" ]; then
    log "Deploying Tesseract CLI shortcut..."
    cp "${SOURCE_DIR}/tesseract.desktop" /usr/share/applications/
    cp "${SOURCE_DIR}/tesseract.desktop" "$KASM_HOME/Desktop/"
fi

# 2. Tesseract Documentation (URL Link)
log "Deploying Tesseract Documentation Link..."
cat <<EOF > /usr/share/applications/documentation.desktop
[Desktop Entry]
Version=1.0
Type=Link
Name=Tesseract Documentation
Comment=Official Command-Line Usage Guide
Icon=accessories-dictionary
Categories=Documentation;
URL=https://github.com/tesseract-ocr/tessdoc/blob/main/Command-Line-Usage.md
EOF

# 3. NormCap (OCR Tool) & Documentation
log "Configuring NormCap UI and Help..."
cat <<EOF > /usr/share/applications/normcap.desktop
[Desktop Entry]
Name=NormCap (OCR)
Comment=Highlight screen to copy text
Exec=/usr/local/bin/normcap
Icon=utilities-terminal
Type=Application
Categories=Graphics;OCR;
EOF

cat <<EOF > /usr/share/applications/normcap-doc.desktop
[Desktop Entry]
Version=1.0
Type=Link
Name=NormCap Documentation
Comment=Usage and Shortcuts
Icon=help-browser
Categories=Documentation;
URL=https://dynasite.github.io/normcap/
EOF

# 4. Final Permissions and Database Refresh
log "Finalizing permissions and refreshing Start Menu..."
# Ensure kasm user owns everything on the desktop
chown -R 1000:1000 "$KASM_HOME/Desktop/"
# Make shortcuts executable (essential for XFCE/Ubuntu 'Allow Launching')
chmod +x "$KASM_HOME/Desktop/"*.desktop 2>/dev/null || true

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

log "Tesseract Environment UI configuration complete!"
