#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Creates a visual status check for Tor SOCKS reachability.
###############################################################################
set -euo pipefail
log() { echo "[torsocks-ui] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Creating Torsocks Guard UI components..."

cat >/usr/share/applications/torsocks-status.desktop <<EOF
[Desktop Entry]
Name=Tor SOCKS Status
Comment=Check if Tor SOCKS Proxy is reachable
Exec=xfce4-terminal --title="Tor Status" --hold --command="torsocks-guard status"
Icon=network-vpn
Terminal=false
Type=Application
Categories=Network;Security;
EOF

chmod +x /usr/share/applications/torsocks-status.desktop

# Copy to Desktop for immediate access
mkdir -p "$KASM_HOME/Desktop"
cp /usr/share/applications/torsocks-status.desktop "$KASM_HOME/Desktop/"
chmod +x "$KASM_HOME/Desktop/torsocks-status.desktop"
chown 1000:0 "$KASM_HOME/Desktop/torsocks-status.desktop" 2>/dev/null || true

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

log "Torsocks UI integration complete."
