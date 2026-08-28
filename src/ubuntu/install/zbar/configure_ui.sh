#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Installs the zbar-scan launcher, the Applications-menu entry
#          (Graphics), and the Desktop shortcut.
###############################################################################
set -euo pipefail

log() { echo "[zbar-ui] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Installing the zbar-scan launcher..."
# zbarcam needs a V4L2 device (/dev/video0), which most Kasm workspaces do not
# expose. This wrapper uses the webcam when one is present, otherwise scans an
# image the user picks. It runs in a terminal so results / errors are visible.
cat > /usr/local/bin/zbar-scan <<'EOF'
#!/usr/bin/env bash
set -u

if [ -e /dev/video0 ]; then
    echo "Webcam detected - starting the live scanner. Press Ctrl-C to stop."
    echo
    exec zbarcam
fi

echo "No webcam is attached to this workspace."
echo "Pick an image (screenshot, photo, download) that contains a barcode or QR code."
echo

img=""
if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    img="$(zenity --file-selection --title='ZBar - pick a barcode / QR image' 2>/dev/null || true)"
fi
if [ -z "$img" ]; then
    read -rp "Path to image file: " img
fi

if [ -z "$img" ] || [ ! -f "$img" ]; then
    echo "No readable file selected."
    read -rp "Press Enter to close..." _
    exit 1
fi

echo
echo "Scanning: $img"
echo "----------------------------------------"
zbarimg --quiet -- "$img" || echo "(no barcode or QR code found)"
echo "----------------------------------------"
read -rp "Press Enter to close..." _
EOF
chmod 0755 /usr/local/bin/zbar-scan

log "Writing the Applications-menu entry (Graphics)..."
cat > /usr/share/applications/zbar-scan.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ZBar Barcode Scanner
GenericName=Barcode / QR Scanner
Comment=Scan barcodes and QR codes from the webcam or an image file
Exec=xfce4-terminal --title=ZBar --command=/usr/local/bin/zbar-scan
Icon=scanner
Terminal=false
Categories=Graphics;Utility;
Keywords=barcode;qr;qrcode;scan;zbar;
EOF
chmod 0644 /usr/share/applications/zbar-scan.desktop

# Drop the old name if a previous build left it behind.
rm -f /usr/share/applications/zbarcam.desktop "${KASM_HOME}/Desktop/zbarcam.desktop"

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

# Desktop icon (opt-in via ZBAR_DESKTOP_ICON=true; default off)
desktop_icon zbar /usr/share/applications/zbar-scan.desktop false

log "ZBar UI configuration complete."
