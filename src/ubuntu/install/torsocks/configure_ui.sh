#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Creates a visual status check for Tor SOCKS reachability.
###############################################################################
set -euo pipefail
log() { echo "[torsocks-ui] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

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

chmod 0644 /usr/share/applications/torsocks-status.desktop

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

# Desktop icon (opt-in via TORSOCKS_DESKTOP_ICON=true; default off)
desktop_icon torsocks /usr/share/applications/torsocks-status.desktop false

log "Torsocks UI integration complete."
