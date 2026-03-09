#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# 
# Purpose: Creates a Terminal-based launcher for TorBoost
###############################################################################
set -euo pipefail
log() { echo "[torboost-ui] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Creating Terminal-based launcher for TorBoost..."

# We use xfce4-terminal (standard in Kasm) to run the boost command
cat >/usr/share/applications/torboost.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=TorBoost Monitor
Comment=Launch TorBoost Circuit Multiplexer
Exec=xfce4-terminal --title="TorBoost" --command="torboost"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Network;Security;
EOF

chmod +x /usr/share/applications/torboost.desktop

# Copy to Desktop
mkdir -p "$KASM_HOME/Desktop"
cp /usr/share/applications/torboost.desktop "$KASM_HOME/Desktop/"
chmod +x "$KASM_HOME/Desktop/torboost.desktop"
chown 1000:1000 "$KASM_HOME/Desktop/torboost.desktop"

# Refresh Menu
if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

log "TorBoost UI integration complete."
